import 'package:flutter/material.dart';

/// Вкладка MaMa AI — ассистент (заглушка; позже — чат на Claude API).
class MamaAiScreen extends StatelessWidget {
  const MamaAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MaMa AI')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 72, color: Color(0xFF7C5CFC)),
              const SizedBox(height: 16),
              const Text('Умный помощник для мам',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Задавайте вопросы о беременности и развитии малыша — '
                'ответы с заботой и ссылкой к врачу при необходимости.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Скоро'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
