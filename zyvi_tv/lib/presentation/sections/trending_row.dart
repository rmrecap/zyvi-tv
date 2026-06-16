import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/channel_model.dart';
import '../../data/providers/channel_provider.dart';
import '../widgets/compact_channel_card.dart';

class TrendingRow extends ConsumerWidget {
  const TrendingRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(allChannelsProvider);
    return channelsAsync.when(
      data: (channels) {
        final trending = channels.where((c) => c.isLive).toList();
        if (trending.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  const Text(
                    'Trending',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'See all',
                    style: TextStyle(
                      color: AppTheme.accentPurple.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: trending.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final channel = trending[index];
                  return CompactChannelCard(
                    channel: channel,
                    onTap: () => _onChannelTap(context, ref, channel),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 120),
      error: (_, __) => SizedBox(
        height: 120,
        child: Center(
          child: OutlinedButton.icon(
            onPressed: () => ref.invalidate(allChannelsProvider),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentPurple,
              side: const BorderSide(color: AppTheme.accentPurple),
            ),
          ),
        ),
      ),
    );
  }

  void _onChannelTap(BuildContext context, WidgetRef ref, ChannelModel channel) {
    if (channel.sources.isEmpty) return;
    final source = channel.sources.first;
    Navigator.pushNamed(context, '/player', arguments: source);
  }
}
