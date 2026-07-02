import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../timeline/widgets/journey_timeline.dart';
import '../kick_counter/widgets/kick_heart_button.dart';

enum ProfileMode { pregnancy, child }

/// Главный экран с бесшовным переключением режимов «беременность» / «ребёнок».
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProfileMode _mode = ProfileMode.pregnancy;
  int _step = 33;   // 34-я неделя
  int _kicks = 0;

  bool get _isPregnancy => _mode == ProfileMode.pregnancy;

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: _isPregnancy ? AppTheme.pregnancy() : AppTheme.child(),
      duration: const Duration(milliseconds: 500),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(_isPregnancy ? 'Беременность' : 'Ерасыл'),
            actions: [
              // Переключение профиля (демо). В проде — из ProfileSwitchBloc.
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: () => setState(() {
                  _mode = _isPregnancy ? ProfileMode.child : ProfileMode.pregnancy;
                  _step = _isPregnancy ? 33 : 2;
                }),
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 16),
              JourneyTimeline(
                totalSteps: _isPregnancy ? 42 : 24,
                currentStep: _step,
                unitLabel: _isPregnancy ? 'неделя' : 'месяц',
                onStepChanged: (s) => setState(() => _step = s),
              ),
              const Spacer(),
              if (_isPregnancy)
                KickHeartButton(
                  count: _kicks,
                  onKick: () => setState(() => _kicks++),
                )
              else
                const Text('Календарь вакцинации и навыков',
                    style: TextStyle(fontSize: 18)),
              const Spacer(),
              if (_isPregnancy && _step >= 37)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.celebration),
                    label: const Text('Я родила!'),
                    onPressed: () => setState(() {
                      _mode = ProfileMode.child;
                      _step = 0;
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
