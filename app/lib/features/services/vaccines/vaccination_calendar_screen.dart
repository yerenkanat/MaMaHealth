import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/child_vaccines.dart';
import '../../../domain/models/profile.dart';
import '../../profile_switch/bloc/profile_switch_bloc.dart';

/// Календарь прививок ребёнка (нац. календарь РК, справочно).
/// Если есть активный профиль ребёнка — отмечает пройденные по возрасту.
class VaccinationCalendarScreen extends StatelessWidget {
  const VaccinationCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Календарь прививок')),
      body: BlocBuilder<ProfileSwitchBloc, ProfileSwitchState>(
        builder: (context, state) {
          // возраст ребёнка в месяцах (если есть детский профиль)
          final child = state.profiles
              .where((p) => p.type == ProfileType.child)
              .cast<Profile?>()
              .firstWhere((_) => true, orElse: () => null);
          final childMonths = child?.currentStep;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E0FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF6A4BD0)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        childMonths == null
                            ? 'Справочный национальный календарь прививок. Точные сроки уточняйте у педиатра.'
                            : 'Отмечено по возрасту: ${child!.title}, ~$childMonths мес. Точные сроки — у педиатра.',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF4A3B8A)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final g in ChildVaccines.schedule)
                _GroupCard(
                  group: g,
                  done: childMonths != null && childMonths >= g.ageMonths,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.done});
  final VaccineGroup group;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      done ? const Color(0xFFD9F2E6) : const Color(0xFFF1EEF7),
                  child: Icon(
                    done ? Icons.check : Icons.vaccines,
                    size: 18,
                    color: done
                        ? const Color(0xFF2E9E6E)
                        : const Color(0xFF6A4BD0),
                  ),
                ),
                const SizedBox(width: 12),
                Text(group.ageLabel,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (done)
                  const Text('пройдено',
                      style: TextStyle(
                          color: Color(0xFF2E9E6E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            for (final v in group.vaccines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.inkMuted)),
                    Expanded(
                        child: Text(v,
                            style: const TextStyle(color: Colors.black87))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
