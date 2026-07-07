import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'engagement_service.dart';

/// Инбокс медицинских напоминаний (скрининги, прививки, осмотры).
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  IconData _icon(String category) => switch (category) {
        'vaccination' => Icons.vaccines,
        'screening' => Icons.monitor_heart_outlined,
        'cycle' => Icons.water_drop,
        _ => Icons.event_available,
      };

  String _when(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Напоминания')),
      body: FutureBuilder<List<Reminder>>(
        future: context.read<EngagementService>().reminders(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Ошибка: ${snap.error}'));
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Пока нет напоминаний 🎉',
                    style: TextStyle(color: Colors.black54)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = items[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: r.isCritical
                          ? const Color(0xFFFDE0E6)
                          : const Color(0xFFE7E0FB),
                      child: Icon(_icon(r.category),
                          color: r.isCritical
                              ? const Color(0xFFD53A5E)
                              : const Color(0xFF6A4BD0)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(_when(r.fireDate),
                              style: const TextStyle(color: AppColors.inkMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                    if (r.isCritical)
                      const Text('важно',
                          style: TextStyle(
                              color: Color(0xFFD53A5E),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
