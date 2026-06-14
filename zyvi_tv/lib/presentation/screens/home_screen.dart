import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/channel_model.dart';
import '../../data/providers/ad_provider.dart';
import '../../data/providers/channel_provider.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/channel_card.dart';
import '../widgets/channel_details_bottom_sheet.dart';
import '../widgets/filter_bar.dart';
import '../widgets/shimmer_loader.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    final selectedIndex = ref.watch(selectedFilterIndexProvider);
    final filterLabel = AppConstants.filterCategories[selectedIndex];
    final isLiveNow = filterLabel == 'LIVE NOW';

    // Lazily switch category on filter change
    if (!isLiveNow) {
      ref.read(paginatedChannelsProvider.notifier).loadCategory(filterLabel);
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  Image.asset('assets/images/main_logo.png', height: 32, fit: BoxFit.contain),
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
                  const Icon(Icons.settings, color: AppTheme.textSecondary),
                ],
              ),
            ),
            const FilterBar(),
            const SizedBox(height: 4),
            Expanded(
              child: isLiveNow
                  ? _buildLiveChannels()
                  : _buildPaginatedChannels(),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveChannels() {
    final channelsAsync = ref.watch(liveChannelsProvider);
    return channelsAsync.when(
      data: (channels) => _buildChannelList(channels, false),
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
    );
  }

  Widget _buildPaginatedChannels() {
    final paginatedAsync = ref.watch(paginatedChannelsProvider);
    return paginatedAsync.when(
      data: (state) {
        if (state.channels.isEmpty) {
          return const Center(
            child: Text(
              'No channels right now',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          );
        }
        return _buildChannelList(state.channels, state.isLoadingMore);
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
    );
  }

  Widget _buildChannelList(List<ChannelModel> channels, bool isLoadingMore) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
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

  void _onChannelTap(BuildContext context, WidgetRef ref, ChannelModel channel) {
    final adManager = ref.read(adManagerProvider);
    if (adManager.canShowInterstitial) {
      adManager.loadInterstitial();
    }

    ChannelDetailsBottomSheet.show(
      context,
      channel,
      onPlayStream: (source) => _onPlayStream(context, ref, source),
    );
  }

  void _onPlayStream(
      BuildContext context, WidgetRef ref, StreamSource source) {
    final adManager = ref.read(adManagerProvider);
    adManager.showInterstitialIfAvailable(
      onDismissed: () {
        Navigator.pushNamed(context, '/player', arguments: source);
      },
    );
  }
}
