import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/pregnancy_weeks.dart';
import '../../../domain/models/week_info.dart';
import '../../kick_counter/widgets/kick_heart_button.dart';
import 'virtual_fetus.dart';

/// Понедельный календарь беременности: hero-блок, виртуальный плод,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroCard(week: week, info: info),
          const SizedBox(height: 18),
          SizedBox(height: 210, child: VirtualFetus(week: week)),
          const SizedBox(height: 14),
          _InfoCard(
            title: 'О малыше',
            text: info.aboutBaby,
            gradient: AppGradients.lavender,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'О Вас',
            text: info.aboutYou,
            gradient: AppGradients.mint,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Рекомендуем',
            text: info.tip,
            gradient: AppGradients.peach,
          ),
          const SizedBox(height: 26),
          const Text('Трекер шевелений',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Center(child: KickHeartButton(count: kicks, onKick: onKick)),
          const SizedBox(height: 18),
          const Text(
            'Информация носит справочный характер и не заменяет консультацию врача.',
            style: TextStyle(fontSize: 12, color: Colors.black38),
          ),
          if (footer != null) ...[const SizedBox(height: 16), footer!],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.week, required this.info});
  final int week;
  final WeekInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: AppGradients.hero,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C6BE8).withValues(alpha: 0.32),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('НЕДЕЛЯ',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600)),
                Text('$week',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        height: 1,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('${info.fruit} · ${info.lengthCm}',
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(info.emoji, style: const TextStyle(fontSize: 60)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(info.weight,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.text,
    required this.gradient,
  });

  final String title;
  final String text;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: gradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text(text,
              style: const TextStyle(
                  fontSize: 14.5, height: 1.4, color: Colors.white)),
        ],
      ),
    );
  }
}
