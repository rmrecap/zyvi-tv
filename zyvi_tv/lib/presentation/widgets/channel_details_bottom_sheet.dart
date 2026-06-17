import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/channel_model.dart';

class ChannelDetailsBottomSheet extends StatelessWidget {
  final ChannelModel channel;
  final void Function(StreamSource source)? onPlayStream;

  const ChannelDetailsBottomSheet({
    super.key,
    required this.channel,
    this.onPlayStream,
  });

  static void show(
    BuildContext context,
    ChannelModel channel, {
    void Function(StreamSource source)? onPlayStream,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChannelDetailsBottomSheet(
        channel: channel,
        onPlayStream: onPlayStream,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0D14).withValues(alpha: 0.88),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        channel.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (channel.isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: AppTheme.neonGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  channel.category,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: channel.sources
                          .map((source) => _sourceChip(context, source))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sourceChip(BuildContext context, StreamSource source) {
    final qualityGradient = _qualityGradient(source.resolutionQuality);
    final isHighQuality = source.resolutionQuality.toUpperCase() == '4K' ||
        source.resolutionQuality.toUpperCase() == 'FHD';

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (onPlayStream != null) {
          onPlayStream!(source);
        } else {
          Navigator.pushNamed(context, '/player', arguments: {
            'channels': [channel],
            'index': 0,
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: isHighQuality ? 0.12 : 0.06),
          ),
          boxShadow: isHighQuality
              ? [
                  BoxShadow(
                    color: AppTheme.accentPurple.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam,
                      color: AppTheme.accentPurple, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    source.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: qualityGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  source.resolutionQuality,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _qualityGradient(String quality) {
    switch (quality.toUpperCase()) {
      case '4K':
        return const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFF7C948)]);
      case 'FHD':
        return const LinearGradient(
            colors: [Color(0xFF7F00FF), Color(0xFFE100FF)]);
      default:
        return const LinearGradient(
            colors: [Color(0xFF2E86DE), Color(0xFF54A0FF)]);
    }
  }
}
