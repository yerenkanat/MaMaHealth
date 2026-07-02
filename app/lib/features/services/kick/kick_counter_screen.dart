import 'package:flutter/material.dart';

import '../../kick_counter/widgets/kick_heart_button.dart';

/// Отдельный экран «Счётчик толчков» (сервис).
class KickCounterScreen extends StatefulWidget {
  const KickCounterScreen({super.key});

  @override
  State<KickCounterScreen> createState() => _KickCounterScreenState();
}

class _KickCounterScreenState extends State<KickCounterScreen> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Счётчик толчков')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Нажимайте при каждом шевелении малыша',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          Center(
            child: KickHeartButton(
              count: _count,
              onKick: () => setState(() => _count++),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => setState(() => _count = 0),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}
