import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/profile.dart';
import '../../growth/widgets/growth_section.dart';
import '../../pregnancy/widgets/pregnancy_calendar.dart';
import '../../profile_switch/bloc/profile_switch_bloc.dart';

/// Standalone-экран календаря беременности (из плитки «Сервисы»).
class PregnancyCalendarScreen extends StatefulWidget {
  const PregnancyCalendarScreen({super.key});

  @override
  State<PregnancyCalendarScreen> createState() => _PregnancyCalendarScreenState();
}

class _PregnancyCalendarScreenState extends State<PregnancyCalendarScreen> {
  int _kicks = 0;

  Profile? _pregnancy(ProfileSwitchState s) {
    for (final p in s.profiles) {
      if (p.type == ProfileType.pregnancy) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Календарь беременности')),
      body: BlocBuilder<ProfileSwitchBloc, ProfileSwitchState>(
        builder: (context, state) {
          final preg = _pregnancy(state);
          if (preg == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Нет активной беременности',
                    style: TextStyle(color: Colors.black54)),
              ),
            );
          }
          return PregnancyCalendar(
            week: preg.currentStep + 1,
            kicks: _kicks,
            onKick: () => setState(() => _kicks++),
          );
        },
      ),
    );
  }
}

/// Standalone-экран календаря развития ребёнка (из плитки «Сервисы»).
class ChildGrowthScreen extends StatelessWidget {
  const ChildGrowthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Календарь развития ребёнка')),
      body: BlocBuilder<ProfileSwitchBloc, ProfileSwitchState>(
        builder: (context, state) {
          String? gender;
          for (final p in state.profiles) {
            if (p.type == ProfileType.child) {
              gender = p.gender;
              break;
            }
          }
          if (gender == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Нет профиля ребёнка',
                    style: TextStyle(color: Colors.black54)),
              ),
            );
          }
          return GrowthSection(gender: gender);
        },
      ),
    );
  }
}
