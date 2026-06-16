import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../services/hive_cache_service.dart';
import '../models/channel_model.dart';

const int _pageSize = 20;

final liveChannelsProvider =
    StreamProvider.autoDispose<List<ChannelModel>>((ref) {
  try {
    final firestore = FirebaseFirestore.instance;
    return firestore
        .collection('zyvi_channels')
        .where('isLive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChannelModel.fromMap(doc.data(), doc.id);
      }).toList();
    }).handleError((_) => <ChannelModel>[]);
  } catch (_) {
    return const Stream.empty();
  }
});

final hiveCacheServiceProvider = Provider<HiveCacheService>((ref) {
  return hiveCacheService;
});

final allChannelsProvider =
    AsyncNotifierProvider<ChannelsNotifier, List<ChannelModel>>(
  ChannelsNotifier.new,
);

class ChannelsNotifier extends AsyncNotifier<List<ChannelModel>> {
  @override
  Future<List<ChannelModel>> build() async {
    final hive = ref.read(hiveCacheServiceProvider);

    try {
      final cached = hive.getCachedChannels();
      if (cached.isNotEmpty) {
        final prioritized = _prioritizeChannels(cached);
        _backgroundSync(hive);
        return prioritized;
      }
    } catch (_) {
      // Hive read failed — fall through to network
    }

    try {
      final channels = await _fetchAndCache(hive)
          .timeout(const Duration(seconds: 5));
      return _prioritizeChannels(channels);
    } catch (_) {
      try {
        final fallback = hive.getCachedChannels();
        if (fallback.isNotEmpty) return _prioritizeChannels(fallback);
      } catch (_) {}
      return [];
    }
  }

  /// Maximum number of priority slots at the top of the list.
  static const int _prioritySlots = 6;

  /// Returns true when [channel] qualifies for a top priority slot.
  static bool _isPriorityChannel(ChannelModel c) {
    final cat = c.category.toLowerCase();
    final name = c.name.toLowerCase();
    final text = '$cat $name';
    return c.isLive ||
        text.contains('world cup') ||
        text.contains('worldcup') ||
        text.contains('sports') ||
        text.contains('sport') ||
        text.contains('fifa') ||
        text.contains('tournament') ||
        text.contains('championship') ||
        text.contains('champion') ||
        text.contains('match') ||
        text.contains('cricket') ||
        text.contains('football') ||
        text.contains('soccer') ||
        text.contains('basketball') ||
        text.contains('tennis') ||
        text.contains('olympic') ||
        text.contains('ufc') ||
        text.contains('wwe') ||
        text.contains('boxing') ||
        text.contains('motogp') ||
        text.contains('formula 1') ||
        text.contains('f1 ') ||
        text.contains('nba') ||
        text.contains('nfl') ||
        text.contains('mlb') ||
        text.contains('nhl');
  }

  /// Pins priority channels at indexes 0–5, keeps the rest in their original
  /// order below. The result always has the same length as [channels].
  static List<ChannelModel> _prioritizeChannels(List<ChannelModel> channels) {
    if (channels.length <= _prioritySlots) return channels;
    final priority = <ChannelModel>[];
    final rest = <ChannelModel>[];
    for (final c in channels) {
      if (priority.length < _prioritySlots && _isPriorityChannel(c)) {
        priority.add(c);
      } else {
        rest.add(c);
      }
    }
    return [...priority, ...rest];
  }

  Future<void> _backgroundSync(HiveCacheService hive) async {
    try {
      final serverConfig = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('config')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 3));
      final serverTimestamp =
          (serverConfig.data()?['last_updated'] as num?)?.toInt() ?? 0;
      final localTimestamp = hive.lastUpdatedTimestamp;

      if (serverTimestamp == localTimestamp) return;

      final channels = await _fetchAndCache(hive);
      state = AsyncData(_prioritizeChannels(channels));
    } catch (_) {
      // Background sync failed — cached data remains
    }
  }

  Future<List<ChannelModel>> _fetchAndCache(HiveCacheService hive) async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('zyvi_channels')
        .orderBy('updatedAt', descending: true)
        .get()
        .timeout(const Duration(seconds: 5));

    final channels = snapshot.docs
        .map((doc) => ChannelModel.fromMap(doc.data(), doc.id))
        .toList();

    await hive.cacheChannels(channels);

    final serverConfig = await firestore
        .collection('app_settings')
        .doc('config')
        .get()
        .timeout(const Duration(seconds: 3));
    final serverTimestamp =
        (serverConfig.data()?['last_updated'] as num?)?.toInt() ?? 0;
    hive.lastUpdatedTimestamp = serverTimestamp;

    return channels;
  }

  Future<void> fullSync() async {
    final current = state;
    if (current is AsyncData && (current.valueOrNull?.isNotEmpty == true)) {
      try {
        final hive = ref.read(hiveCacheServiceProvider);
        final channels = await _fetchAndCache(hive);
        state = AsyncData(_prioritizeChannels(channels));
      } catch (_) {}
    } else {
      state = const AsyncLoading();
      try {
        final hive = ref.read(hiveCacheServiceProvider);
        final channels = await _fetchAndCache(hive);
        state = AsyncData(_prioritizeChannels(channels));
      } catch (err, st) {
        state = AsyncError(err, st);
      }
    }
  }
}

final categoriesProvider = FutureProvider<List<CategoryInfo>>((ref) async {
  final channels = await ref.watch(allChannelsProvider.future);
  final map = <String, int>{};
  for (final c in channels) {
    if (c.category.isNotEmpty) {
      map[c.category] = (map[c.category] ?? 0) + 1;
    }
  }
  final entries = map.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries
      .map((e) => CategoryInfo(name: e.key, channelCount: e.value))
      .toList();
});

class CategoryInfo {
  final String name;
  final int channelCount;
  const CategoryInfo({required this.name, required this.channelCount});
}

class PaginatedChannelsNotifier
    extends AsyncNotifier<PaginatedChannelState> {
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  String _currentCategory = '';

  @override
  Future<PaginatedChannelState> build() async {
    _currentCategory = '';
    _lastDoc = null;
    _hasMore = true;
    return const PaginatedChannelState(channels: [], isLoadingMore: false);
  }

  Future<void> loadCategory(String category) async {
    if (category == _currentCategory) return;
    _currentCategory = category;
    _lastDoc = null;
    _hasMore = true;

    state = const AsyncLoading();

    try {
      final query = FirebaseFirestore.instance
          .collection('zyvi_channels')
          .where('category', isEqualTo: category)
          .orderBy('name')
          .limit(_pageSize);

      final snapshot = await query.get();
      final channels = snapshot.docs.map((doc) {
        return ChannelModel.fromMap(doc.data(), doc.id);
      }).toList();

      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMore = snapshot.docs.length >= _pageSize;

      state = AsyncData(PaginatedChannelState(
        channels: channels,
        isLoadingMore: false,
      ));
    } catch (err, st) {
      state = AsyncError(err, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      Query query = FirebaseFirestore.instance
          .collection('zyvi_channels')
          .where('category', isEqualTo: _currentCategory)
          .orderBy('name')
          .limit(_pageSize);

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();
      final newChannels = snapshot.docs.map((doc) {
        return ChannelModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMore = snapshot.docs.length >= _pageSize;

      state = AsyncData(PaginatedChannelState(
        channels: [...current.channels, ...newChannels],
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

class PaginatedChannelState {
  final List<ChannelModel> channels;
  final bool isLoadingMore;

  const PaginatedChannelState({
    required this.channels,
    required this.isLoadingMore,
  });

  PaginatedChannelState copyWith({
    List<ChannelModel>? channels,
    bool? isLoadingMore,
  }) {
    return PaginatedChannelState(
      channels: channels ?? this.channels,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final paginatedChannelsProvider =
    AsyncNotifierProvider<PaginatedChannelsNotifier, PaginatedChannelState>(
  PaginatedChannelsNotifier.new,
);

final selectedFilterIndexProvider = StateProvider<int>((ref) => 0);
