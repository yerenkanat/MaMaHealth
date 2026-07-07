import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/child_months.dart';
import '../../../domain/models/month_info.dart';
import '../../growth/widgets/growth_section.dart';

/// Календарь развития ребёнка: hero-блок, навыки, прививки, совет + график роста.
class ChildCalendar extends StatelessWidget {
  const ChildCalendar({super.key, required this.month, required this.gender});

  final int month;
  final String gender;

  @override
  Widget build(BuildContext context) {
    final info = ChildMonths.of(month);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroCard(month: month, info: info),
          const SizedBox(height: 14),
          _InfoCard(
            title: 'Навыки',
            text: info.milestone,
            icon: Icons.emoji_people,
            gradient: AppGradients.lavender,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Прививки и осмотры',
            text: info.vaccination,
            icon: Icons.vaccines,
            gradient: AppGradients.peach,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Совет',
            text: info.tip,
            icon: Icons.lightbulb_outline,
            gradient: AppGradients.mint,
          ),
          const SizedBox(height: 22),
          SizedBox(height: 420, child: GrowthSection(gender: gender)),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.month, required this.info});
  final int month;
  final MonthInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: AppGradients.mint,
        boxShadow: [
          BoxShadow(
            color: AppColors.mint.withValues(alpha: 0.30),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ВОЗРАСТ',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600)),
                Text('$month',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        height: 1,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(info.stage,
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
              ],
            ),
          ),
          Text(info.emoji, style: const TextStyle(fontSize: 64)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.text,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String text;
  final IconData icon;
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
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text,
              style: const TextStyle(
                  fontSize: 14.5, height: 1.4, color: Colors.white)),
        ],
      ),
    );
  }
}
