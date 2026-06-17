import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GridCountryCard extends StatelessWidget {
  final String country;
  final int channelCount;
  final VoidCallback onTap;

  const GridCountryCard({
    super.key,
    required this.country,
    required this.channelCount,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _flag(country),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                country,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                '$channelCount channel${channelCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _flag(String country) {
    const flags = {
      'Bangladesh': '\u{1F1E7}\u{1F1E9}',
      'India': '\u{1F1EE}\u{1F1F3}',
      'Pakistan': '\u{1F1F5}\u{1F1F0}',
      'USA': '\u{1F1FA}\u{1F1F8}',
      'UK': '\u{1F1EC}\u{1F1E7}',
      'Canada': '\u{1F1E8}\u{1F1E6}',
      'Australia': '\u{1F1E6}\u{1F1FA}',
      'Brazil': '\u{1F1E7}\u{1F1F7}',
      'France': '\u{1F1EB}\u{1F1F7}',
      'Germany': '\u{1F1E9}\u{1F1EA}',
      'Italy': '\u{1F1EE}\u{1F1F9}',
      'Spain': '\u{1F1EA}\u{1F1F8}',
      'Portugal': '\u{1F1F5}\u{1F1F9}',
      'Netherlands': '\u{1F1F3}\u{1F1F1}',
      'Belgium': '\u{1F1E7}\u{1F1EA}',
      'Switzerland': '\u{1F1E8}\u{1F1ED}',
      'Sweden': '\u{1F1F8}\u{1F1EA}',
      'Norway': '\u{1F1F3}\u{1F1F4}',
      'Denmark': '\u{1F1E9}\u{1F1F0}',
      'Finland': '\u{1F1EB}\u{1F1EE}',
      'Japan': '\u{1F1EF}\u{1F1F5}',
      'South Korea': '\u{1F1F0}\u{1F1F7}',
      'China': '\u{1F1E8}\u{1F1F3}',
      'Russia': '\u{1F1F7}\u{1F1FA}',
      'Turkey': '\u{1F1F9}\u{1F1F7}',
      'UAE': '\u{1F1E6}\u{1F1EA}',
      'Saudi Arabia': '\u{1F1F8}\u{1F1E6}',
      'Qatar': '\u{1F1F6}\u{1F1E6}',
      'Egypt': '\u{1F1EA}\u{1F1EC}',
      'South Africa': '\u{1F1FF}\u{1F1E6}',
      'Argentina': '\u{1F1E6}\u{1F1F7}',
      'Mexico': '\u{1F1F2}\u{1F1FD}',
    };
    return flags[country] ?? '\u{1F310}';
  }
}
