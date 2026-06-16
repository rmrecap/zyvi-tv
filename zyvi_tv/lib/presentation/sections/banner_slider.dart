import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

class BannerSlider extends ConsumerWidget {
  const BannerSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _bannerCard(context, 'https://picsum.photos/seed/live/800/400', 'Live Now'),
          const SizedBox(width: 12),
          _bannerCard(context, 'https://picsum.photos/seed/sports/800/400', 'Sports'),
          const SizedBox(width: 12),
          _bannerCard(context, 'https://picsum.photos/seed/news/800/400', 'News'),
        ],
      ),
    );
  }

  Widget _bannerCard(BuildContext context, String imageUrl, String label) {
    final width = MediaQuery.of(context).size.width * 0.75;
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppTheme.accentPurple.withValues(alpha: 0.6),
            AppTheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
