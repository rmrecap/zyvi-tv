import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color backgroundDark = Color(0xFF080C16);
  static const Color backgroundDeep = Color(0xFF020408);
  static const Color surface = Color(0xFF111625);
  static const Color surfaceLight = Color(0xFF1A2035);
  static const Color shimmerBase = Color(0xFF161C30);
  static const Color shimmerHighlight = Color(0xFF0E1324);
  static const Color surfaceBorder = Color(0xFF1F2C4C);
  static const Color accentPurple = Color(0xFF7F00FF);
  static const Color accentPink = Color(0xFFE100FF);
  static const Color neonGreen = Color(0xFF00FFCC);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A99AD);

  static const Color microBorder = Color(0x0FFFFFFF);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentPurple, accentPink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundDark, backgroundDeep],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxDecoration glassCardDecoration({
    double radius = 16,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: microBorder,
        width: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: accentPurple,
        secondary: accentPink,
        surface: surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accentPurple,
        unselectedItemColor: textSecondary,
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceBorder,
        thickness: 1,
      ),
    );
  }
}
