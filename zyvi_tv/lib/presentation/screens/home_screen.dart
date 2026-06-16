import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

    return _buildHomePage(isLiveNow, liveChannelsAsync, layoutAsync);
  }

  Widget _buildHomePage(
    bool isLiveNow,
    AsyncValue<List<ChannelModel>> liveAsync,
    AsyncValue<List<String>> layoutAsync,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
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
        ),
        const SliverToBoxAdapter(child: FilterBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 4)),
        layoutAsync.when(
          data: (sectionOrder) {
            final sections = <Widget>[];
            if (isLiveNow) {
              sections.addAll(
                sectionOrder
                    .map((id) => _buildSection(id, liveAsync))
                    .where((w) => w != null)
                    .cast<Widget>(),
              );
              sections.add(_buildChannelListSection(liveAsync, 'Live Channels'));
            } else {
              sections.add(_buildPaginatedSection());
            }
            sections.add(const SizedBox(height: 80));
            return SliverList(
              delegate: SliverChildListDelegate(sections),
            );
          },
          loading: () => const SliverToBoxAdapter(child: ShimmerLoader()),
          error: (_, __) => const SliverToBoxAdapter(child: ShimmerLoader()),
        ),
        const SliverToBoxAdapter(child: AdBannerWidget()),
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
      error: (err, _) => _buildRetryWidget(),
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
      error: (err, _) => _buildRetryWidget(),
    );
  }

  Widget _buildChannelList(List<ChannelModel> channels, bool isLoadingMore) {
    return ListView.builder(
      shrinkWrap: true,
      cacheExtent: 300,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: channels.length + (isLoadingMore ? 1 : 0),
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      addAutomaticKeepAlives: false,
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

  Widget _buildRetryWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off,
                color: AppTheme.textSecondary, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Failed to load channels',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(allChannelsProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentPurple,
                side: const BorderSide(color: AppTheme.accentPurple),
              ),
            ),
          ],
        ),
      ),
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
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
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
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
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
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final channel = channels[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 4),
                          child: ChannelCard(
                            channel: channel,
                            onTap: () =>
                                _onChannelTap(context, ref, channel),
                          ),
                        );
                      },
                      childCount: channels.length,
                    ),
                  ),
                ],
              );
            },
            loading: () => const ShimmerLoader(),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off,
                        color: AppTheme.textSecondary, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load live channels',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(allChannelsProvider),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentPurple,
                        side:
                            const BorderSide(color: AppTheme.accentPurple),
                      ),
                    ),
                  ],
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

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
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
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
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
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final channel = recent[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 4),
                          child: ChannelCard(
                            channel: channel,
                            onTap: () =>
                                _onChannelTap(context, ref, channel),
                          ),
                        );
                      },
                      childCount: recent.length,
                    ),
                  ),
                ],
              );
            },
            loading: () => const ShimmerLoader(),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off,
                        color: AppTheme.textSecondary, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load channels',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(allChannelsProvider),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentPurple,
                        side:
                            const BorderSide(color: AppTheme.accentPurple),
                      ),
                    ),
                  ],
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
    Navigator.pushNamed(context, '/player', arguments: source);
    Future.microtask(() {
      try {
        ref.read(adManagerProvider).showInterstitialIfAvailable();
      } catch (_) {}
    });
  }
}
