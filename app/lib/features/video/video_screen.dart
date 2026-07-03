import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

/// Вкладка «Видео» — обучающая лента. Тап открывает подборку на YouTube.
class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});

  static const _videos = <_Video>[
    _Video('Как считать шевеления плода', 'Беременность', '4:12', AppGradients.lavender),
    _Video('Дыхание и позы в родах', 'Роды', '8:30', AppGradients.hero),
    _Video('Первое прикладывание к груди', 'Новорождённый', '6:05', AppGradients.peach),
    _Video('Купание малыша: пошагово', 'Уход', '5:20', AppGradients.mint),
    _Video('Прикорм: с чего начать', 'Питание', '7:48', AppGradients.lavender),
    _Video('Гимнастика для малыша', 'Развитие', '3:55', AppGradients.mint),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Видео')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _videos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) => _VideoCard(video: _videos[i]),
      ),
    );
  }
}

class _Video {
  const _Video(this.title, this.category, this.duration, this.gradient);
  final String title;
  final String category;
  final String duration;
  final Gradient gradient;
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});
  final _Video video;

  Future<void> _open(BuildContext context) async {
    final query = Uri.encodeComponent('${video.title} ${video.category}');
    final uri = Uri.parse('https://www.youtube.com/results?search_query=$query');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть видео')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: video.gradient,
            ),
            child: Stack(
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.play_arrow, size: 34, color: Colors.black87),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(video.duration,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(video.category,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(video.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
      ),
    );
  }
}
