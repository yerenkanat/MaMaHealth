import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/new_child.dart';
import '../../domain/models/profile.dart';
import '../birth_trigger/bloc/birth_trigger_bloc.dart';
import '../kick_counter/widgets/kick_heart_button.dart';
import '../profile_switch/bloc/profile_switch_bloc.dart';
import '../timeline/widgets/journey_timeline.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _kicks = 0; // локальный UI-счётчик шевелений (не часть доменного state)

  @override
  Widget build(BuildContext context) {
    // Слушаем результат миграции «Я родила!» и реагируем на уровне UI.
    return BlocListener<BirthTriggerBloc, BirthTriggerState>(
      listener: (context, birth) {
        if (birth.status == BirthStatus.success && birth.childId != null) {
          HapticFeedback.mediumImpact();
          context.read<ProfileSwitchBloc>().add(ChildAdded(birth.childId!));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Поздравляем с рождением малыша! 🎉')),
          );
        } else if (birth.status == BirthStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: ${birth.error ?? ''}')),
          );
        }
      },
      child: BlocBuilder<ProfileSwitchBloc, ProfileSwitchState>(
        builder: (context, state) {
          switch (state.status) {
            case ProfileStatus.initial:
            case ProfileStatus.loading:
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            case ProfileStatus.error:
              return Scaffold(
                body: Center(child: Text('Ошибка: ${state.error}')),
              );
            case ProfileStatus.ready:
              final profile = state.activeProfile;
              if (profile == null) {
                return const Scaffold(body: Center(child: Text('Нет профилей')));
              }
              return _ProfileView(
                state: state,
                profile: profile,
                kicks: _kicks,
                onKick: () => setState(() => _kicks++),
              );
          }
        },
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.state,
    required this.profile,
    required this.kicks,
    required this.onKick,
  });

  final ProfileSwitchState state;
  final Profile profile;
  final int kicks;
  final VoidCallback onKick;

  @override
  Widget build(BuildContext context) {
    final isPregnancy = profile.isPregnancy;
    return AnimatedTheme(
      data: isPregnancy ? AppTheme.pregnancy() : AppTheme.child(),
      duration: const Duration(milliseconds: 500),
      child: Scaffold(
        appBar: AppBar(
          title: Text(profile.title),
          actions: [
            if (state.profiles.length > 1)
              PopupMenuButton<String>(
                icon: const Icon(Icons.swap_horiz),
                onSelected: (id) =>
                    context.read<ProfileSwitchBloc>().add(ProfileSelected(id)),
                itemBuilder: (_) => [
                  for (final p in state.profiles)
                    PopupMenuItem(value: p.id, child: Text(p.title)),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),
            JourneyTimeline(
              // ключ по профилю → PageController пересоздаётся при переключении
              key: ValueKey(profile.id),
              totalSteps: profile.totalSteps,
              currentStep: profile.currentStep,
              unitLabel: profile.unitLabel,
              onStepChanged: (s) =>
                  context.read<ProfileSwitchBloc>().add(ProfileStepChanged(s)),
            ),
            const Spacer(),
            if (isPregnancy)
              KickHeartButton(count: kicks, onKick: onKick)
            else
              const Text('Календарь вакцинации и навыков',
                  style: TextStyle(fontSize: 18)),
            const Spacer(),
            if (isPregnancy && profile.currentStep >= 37)
              _BirthButton(pregnancyId: profile.id),
          ],
        ),
      ),
    );
  }
}

class _BirthButton extends StatelessWidget {
  const _BirthButton({required this.pregnancyId});
  final String pregnancyId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BirthTriggerBloc, BirthTriggerState>(
      builder: (context, birth) {
        final submitting = birth.status == BirthStatus.submitting;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton.icon(
            icon: const Icon(Icons.celebration),
            label: Text(submitting ? 'Сохраняем...' : 'Я родила!'),
            onPressed: submitting ? null : () => _submit(context),
          ),
        );
      },
    );
  }

  void _submit(BuildContext context) {
    // Упрощённая форма. В проде — bottom-sheet с полями и валидацией.
    final child = NewChild(
      name: 'Ерасыл',
      gender: 'male',
      birthDate: DateTime.now(),
      birthWeightG: 3400,
      birthHeightCm: 52,
    );
    context.read<BirthTriggerBloc>().add(BirthSubmitted(pregnancyId, child));
  }
}
