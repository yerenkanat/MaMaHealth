import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

void main() => runApp(const MaMaApp());

class MaMaApp extends StatelessWidget {
  const MaMaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaMa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.pregnancy(),
      home: const HomeScreen(),
    );
  }
}
