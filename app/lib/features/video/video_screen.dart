import 'package:flutter/material.dart';

/// Вкладка «Видео» — обучающая лента (заглушка).
class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Видео')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, i) => Card(
          elevation: 0,
          color: const Color(0xFFF3F1F7),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_arrow, size: 32),
            ),
            title: Text('Обучающее видео №${i + 1}'),
            subtitle: const Text('Скоро'),
          ),
        ),
      ),
    );
  }
}
