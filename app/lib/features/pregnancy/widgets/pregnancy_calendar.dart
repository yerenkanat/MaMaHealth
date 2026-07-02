import 'package:flutter/material.dart';

import '../../../data/pregnancy_weeks.dart';
import '../../../domain/models/week_info.dart';
import '../../kick_counter/widgets/kick_heart_button.dart';
import 'virtual_fetus.dart';

/// Понедельный календарь беременности: размер-фрукт, вес, виртуальный плод,
/// блоки «О малыше / О Вас / Рекомендуем» и трекер шевелений.
class PregnancyCalendar extends StatelessWidget {
  const PregnancyCalendar({
    super.key,
    required this.week,
    required this.kicks,
    required this.onKick,
    this.footer,
  });

  final int week;
  final int kicks;
  final VoidCallback onKick;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final info = PregnancyWeeks.of(week);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _SizeCard(info)),
              const SizedBox(width: 12),
              Expanded(child: _WeightCard(info)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 220, child: VirtualFetus(week: week)),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'О малыше',
            text: info.aboutBaby,
            colors: const [Color(0xFFFAD0DD), Color(0xFFF8E1EA)],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'О Вас',
            text: info.aboutYou,
            colors: const [Color(0xFFE7DAF7), Color(0xFFDCE7FB)],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Рекомендуем',
            text: info.tip,
            colors: const [Color(0xFFFBF3C4), Color(0xFFD9F2D0)],
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Трекер шевелений',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          Center(child: KickHeartButton(count: kicks, onKick: onKick)),
          const SizedBox(height: 16),
          const Text(
            'Информация носит справочный характер и не заменяет консультацию '
            'лечащего врача.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
          if (footer != null) ...[const SizedBox(height: 16), footer!],
        ],
      ),
    );
  }
}

class _SizeCard extends StatelessWidget {
  const _SizeCard(this.info);
  final WeekInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEBF1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(info.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(info.fruit,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('рост ${info.lengthCm}',
              style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard(this.info);
  final WeekInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2ECFB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.monitor_weight_outlined, size: 40, color: Color(0xFF9B7BD1)),
          const SizedBox(height: 8),
          const Text('Вес',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(info.weight, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.text,
    required this.colors,
  });

  final String title;
  final String text;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(text,
              style: const TextStyle(fontSize: 14, height: 1.35, color: Colors.black87)),
        ],
      ),
    );
  }
}
