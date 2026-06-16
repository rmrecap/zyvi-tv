import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:better_player_enhanced/better_player.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/channel_model.dart';
import '../../data/providers/ad_provider.dart';
import '../../data/providers/app_settings_provider.dart';
import '../../data/providers/channel_provider.dart';
import '../../data/providers/home_layout_provider.dart';
import '../sections/banner_slider.dart';
import '../sections/live_now_row.dart';
import '../sections/news_row.dart';
import '../sections/trending_row.dart';
import '../sections/categories_row.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/channel_card.dart';
import '../widgets/compact_channel_card.dart';
import '../widgets/curved_bottom_nav.dart';
import '../widgets/filter_bar.dart';
import '../widgets/shimmer_loader.dart';
import 'categories_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTab = 0;
  final ScrollController _scrollController = ScrollController();
  final List<BetterPlayerController> _preCacheControllers = [];
  bool _preCached = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialLabel = AppConstants.filterCategories[0];
      if (initialLabel != 'LIVE NOW') {
        ref.read(paginatedChannelsProvider.notifier).loadCategory(initialLabel);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in _preCacheControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(paginatedChannelsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: IndexedStack(
            index: _currentTab,
            children: [
              _buildHomeTab(),
              const CategoriesTab(),
              _buildLiveTab(),
              _buildTrendingTab(),
            ],
          ),
        ),
        bottomNavigationBar: CurvedBottomNav(
          currentIndex: _currentTab,
          onTap: (i) => setState(() => _currentTab = i),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final selectedIndex = ref.watch(selectedFilterIndexProvider);
    final filterLabel = AppConstants.filterCategories[selectedIndex];
    final isLiveNow = filterLabel == 'LIVE NOW';
    final liveChannelsAsync = ref.watch(liveChannelsProvider);
    final layoutAsync = ref.watch(homeLayoutProvider);

    ref.listen<int>(selectedFilterIndexProvider, (_, nextIndex) {
      final label = AppConstants.filterCategories[nextIndex];
      if (label != 'LIVE NOW') {
        ref.read(paginatedChannelsProvider.notifier).loadCategory(label);
      }
    });

    ref.listen<AsyncValue<List<ChannelModel>>>(
      allChannelsProvider,
      (previous, next) {
        next.whenData((channels) {
          if (_preCached || channels.isEmpty) return;
          _preCached = true;
          for (int i = 0; i < channels.length && i < 3; i++) {
            final url = channels[i].sources.isNotEmpty
                ? channels[i].sources.first.url
                : '';
            if (url.isEmpty) continue;
            final cacheCtrl = BetterPlayerController(
              const BetterPlayerConfiguration(autoPlay: false),
            );
            cacheCtrl.preCache(BetterPlayerDataSource.network(
              url,
              cacheConfiguration: const BetterPlayerCacheConfiguration(
                useCache: true,
              ),
            ));
            _preCacheControllers.add(cacheCtrl);
          }
        });
      },
    );

    return _buildHomePage(isLiveNow, liveChannelsAsync, layoutAsync);
  }

  Widget _buildHomePage(
    bool isLiveNow,
    AsyncValue<List<ChannelModel>> liveAsync,
    AsyncValue<List<String>> layoutAsync,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              _buildLogo(),
              const SizedBox(width: 10),
              const Text(
                'Zyvi TV',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/settings'),
                child: const Icon(Icons.settings, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        const FilterBar(),
        const SizedBox(height: 4),
        Expanded(
          child: layoutAsync.when(
            data: (sectionOrder) {
              return ListView(
                physics: const BouncingScrollPhysics(),
                controller: _scrollController,
                children: [
                  if (isLiveNow)
                    ...sectionOrder
                        .map((id) => _buildSection(id, liveAsync))
                        .where((w) => w != null)
                        .cast<Widget>(),
                  if (isLiveNow)
                    _buildChannelListSection(
                      liveAsync,
                      'Live Channels',
                    ),
                  if (!isLiveNow) _buildPaginatedSection(),
                  const SizedBox(height: 80),
                ],
              );
            },
            loading: () => const ShimmerLoader(),
            error: (_, __) => const ShimmerLoader(),
          ),
        ),
        const AdBannerWidget(),
      ],
    );
  }

  Widget? _buildSection(
    String sectionId,
    AsyncValue<List<ChannelModel>> liveAsync,
  ) {
    switch (sectionId) {
      case 'banner_slider':
        return const BannerSlider();
      case 'live_now':
        return const LiveNowRow();
      case 'news_channels':
        return const NewsRow();
      case 'trending':
        return const TrendingRow();
      case 'categories':
        return const CategoriesRow();
      default:
        return null;
    }
  }

  Widget _buildChannelListSection(
    AsyncValue<List<ChannelModel>> channelsAsync,
    String title,
  ) {
    return channelsAsync.when(
      data: (channels) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildChannelList(channels, false),
        ],
      ),
      loading: () => const SizedBox(height: 100, child: ShimmerLoader()),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildPaginatedSection() {
    final paginatedAsync = ref.watch(paginatedChannelsProvider);
    return paginatedAsync.when(
      data: (state) {
        if (state.channels.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No channels right now',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 16),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Text(
                AppConstants.filterCategories[
                    ref.watch(selectedFilterIndexProvider)],
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildChannelList(state.channels, state.isLoadingMore),
          ],
        );
      },
      loading: () => const SizedBox(height: 100, child: ShimmerLoader()),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildChannelList(List<ChannelModel> channels, bool isLoadingMore) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: channels.length + (isLoadingMore ? 1 : 0),
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemBuilder: (context, index) {
        if (index == channels.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accentPurple,
                ),
              ),
            ),
          );
        }
        final channel = channels[index];
        return ChannelCard(
          channel: channel,
          onTap: () => _onChannelTap(context, ref, channel),
        );
      },
    );
  }

  Widget _buildLiveTab() {
    final channelsAsync = ref.watch(liveChannelsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 4),
          child: Text(
            'Live Now',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Currently streaming channels',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: channelsAsync.when(
            data: (channels) {
              if (channels.isEmpty) {
                return const Center(
                  child: Text(
                    'No live channels right now',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 16),
                  ),
                );
              }
              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: channels.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 4),
                      itemBuilder: (context, index) {
                        final channel = channels[index];
                        return CompactChannelCard(
                          channel: channel,
                          onTap: () =>
                              _onChannelTap(context, ref, channel),
                        );
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Text(
                      'All Live Channels',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...channels.map((channel) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 4),
                        child: ChannelCard(
                          channel: channel,
                          onTap: () =>
                              _onChannelTap(context, ref, channel),
                        ),
                      )),
                ],
              );
            },
            loading: () => const ShimmerLoader(),
            error: (err, _) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Failed to load live channels',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingTab() {
    final channelsAsync = ref.watch(allChannelsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 4),
          child: Text(
            'Trending',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Most popular and recently updated',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: channelsAsync.when(
            data: (channels) {
              if (channels.isEmpty) {
                return const Center(
                  child: Text(
                    'No channels yet',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 16),
                  ),
                );
              }
              final live = channels.where((c) => c.isLive).toList();
              final recent = channels
                  .where((c) => !c.isLive)
                  .take(10)
                  .toList();

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: live.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 4),
                      itemBuilder: (context, index) {
                        final channel = live[index];
                        return CompactChannelCard(
                          channel: channel,
                          onTap: () =>
                              _onChannelTap(context, ref, channel),
                        );
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Text(
                      'Recently Updated',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...recent.map((channel) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 4),
                        child: ChannelCard(
                          channel: channel,
                          onTap: () =>
                              _onChannelTap(context, ref, channel),
                        ),
                      )),
                ],
              );
            },
            loading: () => const ShimmerLoader(),
            error: (err, _) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Failed to load channels',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    final settings = ref.watch(appSettingsProvider).settings;
    if (settings.logoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: settings.logoUrl,
        height: 32,
        fit: BoxFit.contain,
        placeholder: (_, __) => Image.asset('assets/images/main_logo.png',
            height: 32, fit: BoxFit.contain),
        errorWidget: (_, __, ___) => Image.asset('assets/images/main_logo.png',
            height: 32, fit: BoxFit.contain),
      );
    }
    return Image.asset('assets/images/main_logo.png',
        height: 32, fit: BoxFit.contain);
  }

  void _onChannelTap(BuildContext context, WidgetRef ref, ChannelModel channel) {
    if (channel.sources.isEmpty) return;
    final source = channel.sources.first;
    final adManager = ref.read(adManagerProvider);
    adManager.showInterstitialIfAvailable(
      onDismissed: () {
        Navigator.pushNamed(context, '/player', arguments: source);
      },
    );
  }
}
