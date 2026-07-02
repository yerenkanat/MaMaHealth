import 'package:flutter/material.dart';

import '../assistant/mama_ai_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../services/services_screen.dart';
import '../video/video_screen.dart';

/// Корневая оболочка с нижней навигацией (5 вкладок).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    ServicesScreen(),
    MamaAiScreen(),
    VideoScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Главная'),
          NavigationDestination(
              icon: Icon(Icons.monitor_heart_outlined),
              selectedIcon: Icon(Icons.monitor_heart),
              label: 'Мониторинг'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'MaMa AI'),
          NavigationDestination(
              icon: Icon(Icons.ondemand_video_outlined),
              selectedIcon: Icon(Icons.ondemand_video),
              label: 'Видео'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Профиль'),
        ],
      ),
    );
  }
}
