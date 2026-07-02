import 'package:flutter/material.dart';

/// Свежая пастель + сочные градиенты. Крупная типографика, большие скругления.
class AppColors {
  static const bg = Color(0xFFF3F4FB);      // прохладный светлый фон
  static const ink = Color(0xFF2A2440);      // тёмный текст
  static const lavender = Color(0xFF8B7BF0);
  static const mint = Color(0xFF39C6A8);
  static const peach = Color(0xFFFF9E7A);
}

class AppGradients {
  static const hero = LinearGradient(
    colors: [Color(0xFF9E8BFF), Color(0xFF6FD6C1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const lavender = LinearGradient(
    colors: [Color(0xFFB6A8FF), Color(0xFF8B7BF0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const mint = LinearGradient(
    colors: [Color(0xFF8FE9CD), Color(0xFF39C6A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const peach = LinearGradient(
    colors: [Color(0xFFFFC79E), Color(0xFFFF8F6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData pregnancy() => _base(AppColors.lavender);
  static ThemeData child() => _base(AppColors.mint);

  static ThemeData _base(Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: seed.withValues(alpha: 0.16),
        elevation: 0,
        height: 68,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
