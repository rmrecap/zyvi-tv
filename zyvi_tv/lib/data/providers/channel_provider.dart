import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../services/hive_cache_service.dart';
import '../models/channel_model.dart';

const int _pageSize = 20;
const int _batchYieldInterval = 200;

Future<List<ChannelModel>> _parseDocsBatched(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
  final channels = <ChannelModel>[];
  for (int i = 0; i < docs.length; i++) {
    channels.add(ChannelModel.fromMap(docs[i].data(), docs[i].id));
    if (i > 0 && i % _batchYieldInterval == 0) {
      await Future.delayed(Duration.zero);
    }
  }
  return channels;
}

final liveChannelsProvider =
    StreamProvider.autoDispose<List<ChannelModel>>((ref) {
  try {
    final firestore = FirebaseFirestore.instance;
    return firestore
        .collection('zyvi_channels')
        .where('isLive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final docs = snapshot.docs
          .map((d) => d as QueryDocumentSnapshot<Map<String, dynamic>>)
          .toList();
      return _parseDocsBatched(docs);
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
        final sorted = _sortPriorityFirst(cached);
        _backgroundSync(hive);
        return sorted;
      }
    } catch (_) {}

    try {
      final channels = await _fetchAndCache(hive)
          .timeout(const Duration(seconds: 5));
      return _sortPriorityFirst(channels);
    } catch (_) {
      try {
        final fallback = hive.getCachedChannels();
        if (fallback.isNotEmpty) return _sortPriorityFirst(fallback);
      } catch (_) {}
      return [];
    }
  }

  static bool _isPriorityChannel(String name, String category) {
    final text = '${category.toLowerCase()} ${name.toLowerCase()}';
    return const [
      'world cup', 'worldcup', 'sports', 'sport', 'fifa', 'tournament',
      'championship', 'champion', 'match', 'cricket', 'football', 'soccer',
      'basketball', 'tennis', 'olympic', 'ufc', 'wwe', 'boxing', 'motogp',
      'formula 1', 'f1 ', 'nba', 'nfl', 'mlb', 'nhl', 'hockey', 'racing',
      'motorsport', 'wrestling', 'badminton', 'volleyball', 'rugby', 'golf',
    ].any((kw) => text.contains(kw));
  }

  static List<ChannelModel> _sortPriorityFirst(List<ChannelModel> channels) {
    if (channels.length <= 6) return channels;
    try {
      final sorted = [...channels];
      sorted.sort((a, b) {
        final aPrio = a.isLive || _isPriorityChannel(a.name, a.category);
        final bPrio = b.isLive || _isPriorityChannel(b.name, b.category);
        if (aPrio && !bPrio) return -1;
        if (!aPrio && bPrio) return 1;
        return 0;
      });
      return sorted;
    } catch (_) {
      return channels;
    }
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
      state = AsyncData(_sortPriorityFirst(channels));
    } catch (_) {}
  }

  Future<List<ChannelModel>> _fetchAndCache(HiveCacheService hive) async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('zyvi_channels')
        .orderBy('updatedAt', descending: true)
        .get()
        .timeout(const Duration(seconds: 5));

    final docs = snapshot.docs
        .map((d) => d as QueryDocumentSnapshot<Map<String, dynamic>>)
        .toList();

    final channels = await _parseDocsBatched(docs);

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
        state = AsyncData(_sortPriorityFirst(channels));
      } catch (_) {}
    } else {
      state = const AsyncLoading();
      try {
        final hive = ref.read(hiveCacheServiceProvider);
        final channels = await _fetchAndCache(hive);
        state = AsyncData(_sortPriorityFirst(channels));
      } catch (err, st) {
        final hive = ref.read(hiveCacheServiceProvider);
        try {
          final fallback = hive.getCachedChannels();
          if (fallback.isNotEmpty) {
            state = AsyncData(_sortPriorityFirst(fallback));
            return;
          }
        } catch (_) {}
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
      final docs = snapshot.docs
          .map((d) => d as QueryDocumentSnapshot<Map<String, dynamic>>)
          .toList();
      final channels = await _parseDocsBatched(docs);

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
      final docs = snapshot.docs
          .map((d) => d as QueryDocumentSnapshot<Map<String, dynamic>>)
          .toList();
      final newChannels = await _parseDocsBatched(docs);

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
