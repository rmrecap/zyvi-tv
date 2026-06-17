import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/channel_model.dart';

class GridChannelCard extends StatelessWidget {
  final ChannelModel channel;
  final VoidCallback onTap;

  const GridChannelCard({
    super.key,
    required this.channel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.microBorder),
          color: AppTheme.surface,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: AppTheme.surfaceLight,
                  child: _buildThumbnail(),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      channel.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (channel.isLive)
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(Icons.fiber_manual_record,
                            color: AppTheme.neonGreen, size: 6),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (channel.logoUrl.isEmpty) {
      return const Center(
        child: Icon(Icons.tv, color: AppTheme.textSecondary, size: 20),
      );
    }

    return CachedNetworkImage(
      imageUrl: channel.logoUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: Icon(Icons.tv, color: AppTheme.textSecondary, size: 20),
      ),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(Icons.tv, color: AppTheme.textSecondary, size: 20),
      ),
    );
  }
}
