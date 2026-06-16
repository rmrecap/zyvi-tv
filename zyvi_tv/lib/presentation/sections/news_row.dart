import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/channel_model.dart';
import '../../data/providers/channel_provider.dart';
import '../widgets/compact_channel_card.dart';

class NewsRow extends ConsumerWidget {
  const NewsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(allChannelsProvider);
    return channelsAsync.when(
      data: (channels) {
        final newsChannels = channels
            .where((c) => c.category.toLowerCase().contains('news'))
            .toList();
        if (newsChannels.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  const Text(
                    'News Channels',
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
                itemCount: newsChannels.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final channel = newsChannels[index];
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
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _onChannelTap(BuildContext context, WidgetRef ref, ChannelModel channel) {
    if (channel.sources.isEmpty) return;
    final source = channel.sources.first;
    Navigator.pushNamed(context, '/player', arguments: source);
  }
}
