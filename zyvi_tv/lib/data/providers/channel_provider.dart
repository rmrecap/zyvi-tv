import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../services/hive_cache_service.dart';
import '../models/channel_model.dart';

const int _pageSize = 20;

List<Map<String, dynamic>> _parseInIsolate(List<Map<String, dynamic>> raw) {
  return raw.map((m) {
    final id = m['__id__'] as String;
    final data = Map<String, dynamic>.from(m);
    data.remove('__id__');
    return ChannelModel.fromMap(data, id).toMap();
  }).toList();
}

DateTime? _tryParseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  try {
    return DateTime.parse('$value');
  } catch (_) {
    return null;
  }
}

Future<List<ChannelModel>> _parseDocsOffMain(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
  final raw = docs.map((d) {
    final m = Map<String, dynamic>.from(d.data());
    m['__id__'] = d.id;
    final updatedAt = _tryParseTimestamp(m['updatedAt']);
    m['updatedAt'] = (updatedAt ?? DateTime.now()).toIso8601String();
    return m;
  }).toList();

  if (raw.length < 100) {
    return raw.map((m) {
      final id = m['__id__'] as String;
      final data = Map<String, dynamic>.from(m);
      data.remove('__id__');
      return ChannelModel.fromMap(data, id);
    }).toList();
  }

  final resultMaps = await compute(_parseInIsolate, raw);
  return resultMaps.map((m) => ChannelModel.fromJson(m)).toList();
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
      return _parseDocsOffMain(snapshot.docs);
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

    final channels = await _parseDocsOffMain(snapshot.docs);

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
      final channels = await _parseDocsOffMain(snapshot.docs);

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
      final newChannels = await _parseDocsOffMain(
          snapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>());

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

final countriesProvider = FutureProvider<List<CountryInfo>>((ref) async {
  final channels = await ref.watch(allChannelsProvider.future);
  final map = <String, int>{};
  for (final c in channels) {
    final country = c.country.trim();
    if (country.isNotEmpty) {
      map[country] = (map[country] ?? 0) + 1;
    }
  }
  final entries = map.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries
      .map((e) => CountryInfo(name: e.key, channelCount: e.value))
      .toList();
});

class CountryInfo {
  final String name;
  final int channelCount;
  const CountryInfo({required this.name, required this.channelCount});
}

final customSectionsProvider =
    FutureProvider<List<CustomSection>>((ref) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('app_settings')
        .doc('custom_sections')
        .get()
        .timeout(const Duration(seconds: 3));
    final data = doc.data();
    if (data == null) return [];
    final list = data['sections'] as List<dynamic>? ?? [];
    return list
        .map((e) => CustomSection.fromMap(e as Map<String, dynamic>))
        .where((s) => s.enabled)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  } catch (_) {
    return [];
  }
});

class CustomSection {
  final String title;
  final int order;
  final int maxItems;
  final List<String> channelIds;
  final bool enabled;

  const CustomSection({
    required this.title,
    required this.order,
    required this.maxItems,
    required this.channelIds,
    required this.enabled,
  });

  factory CustomSection.fromMap(Map<String, dynamic> map) {
    return CustomSection(
      title: map['title'] as String? ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
      maxItems: (map['maxItems'] as num?)?.toInt() ?? 10,
      channelIds: (map['channelIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      enabled: map['enabled'] as bool? ?? true,
    );
  }
}

final selectedCountryProvider = StateProvider<String>((ref) => '');

final countryChannelsProvider =
    FutureProvider.family<List<ChannelModel>, String>((ref, country) async {
  final allChannels = await ref.watch(allChannelsProvider.future);
  if (country.isEmpty) return allChannels;
  return allChannels.where((c) => c.country == country).toList();
});
