import 'package:flutter/material.dart';

/// Две палитры под два режима «непрерывного родительства».
class AppTheme {
  static const softRose = Color(0xFFF7B6C8);   // Режим 1 — беременность
  static const warmPastel = Color(0xFFE9C9A8); // Режим 2 — ребёнок

  static ThemeData pregnancy() => _base(softRose);
  static ThemeData child() => _base(warmPastel);

  static ThemeData _base(Color seed) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFFDFBFA),
      );
}
