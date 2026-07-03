import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/profile.dart';
import '../birth_trigger/bloc/birth_trigger_bloc.dart';
import '../birth_trigger/widgets/birth_form_sheet.dart';
import '../birth_trigger/widgets/confetti_overlay.dart';
import '../child/widgets/child_calendar.dart';
import '../engagement/reminders_screen.dart';
import '../pregnancy/widgets/pregnancy_calendar.dart';
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
          ConfettiOverlay.show(context);
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
            IconButton(
              icon: const Icon(Icons.notifications_none),
              tooltip: 'Напоминания',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RemindersScreen()),
              ),
            ),
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
            if (isPregnancy)
              Expanded(
                child: PregnancyCalendar(
                  week: profile.currentStep + 1,
                  kicks: kicks,
                  onKick: onKick,
                  footer: profile.currentStep >= 37
                      ? _BirthButton(pregnancyId: profile.id)
                      : null,
                ),
              )
            else
              Expanded(
                child: ChildCalendar(
                  month: profile.currentStep,
                  gender: profile.gender ?? 'male',
                ),
              ),
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

  Future<void> _submit(BuildContext context) async {
    final bloc = context.read<BirthTriggerBloc>();
    final child = await BirthFormSheet.show(context);
    if (child == null) return; // пользователь отменил
    bloc.add(BirthSubmitted(pregnancyId, child));
  }
}
