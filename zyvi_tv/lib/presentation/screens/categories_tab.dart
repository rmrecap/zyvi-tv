import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/channel_provider.dart';
import '../widgets/shimmer_loader.dart';

class CategoriesTab extends ConsumerWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 4),
          child: Text(
            'Categories',
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
            'Browse channels by category',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return const Center(
                  child: Text(
                    'No categories found',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return _CategoryCard(category: cat);
                  },
                ),
              );
            },
            loading: () => const ShimmerLoader(),
            error: (err, _) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Failed to load categories',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryInfo category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/category-detail',
            arguments: category.name);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: _gradientForIndex(category.name.hashCode),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentPurple.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _iconForCategory(category.name),
                color: Colors.white.withValues(alpha: 0.9),
                size: 28,
              ),
              const Spacer(),
              Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${category.channelCount} channels',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

LinearGradient _gradientForIndex(int hash) {
  final gradients = [
    const LinearGradient(
      colors: [Color(0xFF7F00FF), Color(0xFF4A00E0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFE100FF), Color(0xFF7F00FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFF00FFCC), Color(0xFF0099FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];
  return gradients[hash.abs() % gradients.length];
}

IconData _iconForCategory(String name) {
  final n = name.toLowerCase();
  if (n.contains('sport')) return Icons.sports_soccer;
  if (n.contains('movie') || n.contains('film')) return Icons.movie;
  if (n.contains('news')) return Icons.article;
  if (n.contains('music')) return Icons.music_note;
  if (n.contains('kids') || n.contains('children')) return Icons.child_care;
  if (n.contains('docu') || n.contains('education')) return Icons.school;
  if (n.contains('entertain')) return Icons.emoji_emotions;
  if (n.contains('bangla') || n.contains('bengali')) return Icons.language;
  if (n.contains('india') || n.contains('hindi')) return Icons.language;
  if (n.contains('live')) return Icons.live_tv;
  return Icons.tv;
}
