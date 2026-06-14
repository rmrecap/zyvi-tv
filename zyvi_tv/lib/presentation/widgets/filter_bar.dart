import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/channel_provider.dart';

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedFilterIndexProvider);

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: AppConstants.filterCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () =>
                ref.read(selectedFilterIndexProvider.notifier).state = index,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.accentGradient : null,
                color: isSelected ? null : AppTheme.surface,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color:
                      isSelected ? Colors.transparent : AppTheme.microBorder,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.accentPurple.withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                AppConstants.filterCategories[index],
                style: TextStyle(
                  color:
                      isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
