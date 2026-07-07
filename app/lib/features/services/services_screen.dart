import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'baby/newborn_tracker_screen.dart';
import 'blood/blood_type_screen.dart';
import 'calendars/calendar_screens.dart';
import 'checklist/checklist_screen.dart';
import 'contractions/contraction_screen.dart';
import 'cycle/cycle_screen.dart';
import 'daily/daily_log_screen.dart';
import 'report/doctor_report_screen.dart';
import 'trends/trends_screen.dart';
import 'vaccines/vaccination_calendar_screen.dart';
import 'kick/kick_counter_screen.dart';
import 'names/baby_names_screen.dart';
import 'tips/allowed_screen.dart';
import 'ultrasound/ultrasound_screen.dart';
import 'weight/weight_monitor_screen.dart';

/// Хаб «Сервисы» (вкладка «Мониторинг») — сетка сервисов приложения.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static const _services = <_Service>[
    _Service('Мой цикл', Icons.calendar_today, Color(0xFFFFE0E6)),
    _Service('Мои тренды', Icons.insights, Color(0xFFE7E0FB)),
    _Service('Дневник малыша', Icons.baby_changing_station, Color(0xFFDCEFFB)),
    _Service('Календарь прививок', Icons.vaccines, Color(0xFFDDF5EC)),
    _Service('Дневник самочувствия', Icons.favorite_border, Color(0xFFFDE7D6)),
    _Service('Отчёт для врача', Icons.summarize_outlined, Color(0xFFDDF5EC)),
    _Service('Выбор имени для ребёнка', Icons.child_care, Color(0xFFDCF1F5)),
    _Service('Чеклисты', Icons.checklist, Color(0xFFFBE0EC)),
    _Service('Календарь беременности', Icons.calendar_month, Color(0xFFE7E0FB)),
    _Service('Календарь развития ребёнка', Icons.baby_changing_station, Color(0xFFDCEFFB)),
    _Service('Расшифровка УЗИ', Icons.person_search, Color(0xFFFDF1D6)),
    _Service('Подготовка к роддому', Icons.local_hospital_outlined, Color(0xFFDDF5EC)),
    _Service('Счётчик схваток', Icons.timer_outlined, Color(0xFFE7E0FB)),
    _Service('Счётчик толчков', Icons.favorite_outline, Color(0xFFFBE0EC)),
    _Service('Группа крови младенца', Icons.bloodtype_outlined, Color(0xFFFBE0E0)),
    _Service('Монитор веса мамы', Icons.monitor_weight_outlined, Color(0xFFE7E0FB)),
    _Service('Что можно есть', Icons.restaurant_outlined, Color(0xFFFDE4D6)),
    _Service('Что можно делать', Icons.self_improvement, Color(0xFFFBE0EC)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сервисы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Поиск по сервисам',
            onPressed: () =>
                showSearch(context: context, delegate: _ServiceSearchDelegate()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
        children: [
          for (final s in _services) _ServiceTile(service: s),
        ],
      ),
    );
  }
}

/// Поиск по сервисам (встроенный SearchDelegate).
class _ServiceSearchDelegate extends SearchDelegate<void> {
  @override
  String get searchFieldLabel => 'Найти сервис';

  List<_Service> _matches() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return ServicesScreen._services;
    return ServicesScreen._services
        .where((s) => s.title.toLowerCase().contains(q))
        .toList();
  }

  Widget _list(BuildContext context) {
    final items = _matches();
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Ничего не найдено',
              style: TextStyle(color: AppColors.inkMuted)),
        ),
      );
    }
    return ListView(
      children: [
        for (final s in items)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: s.color,
              child: Icon(s.icon, color: Colors.black87, size: 20),
            ),
            title: Text(s.title),
            onTap: () {
              close(context, null);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => _screenFor(s.title)),
              );
            },
          ),
      ],
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Очистить',
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Назад',
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _list(context);

  @override
  Widget buildSuggestions(BuildContext context) => _list(context);
}

/// Маршрутизация плитки на реальный экран (или заглушку).
Widget _screenFor(String title) {
  switch (title) {
    case 'Мой цикл':
      return const CycleScreen();
    case 'Мои тренды':
      return const TrendsScreen();
    case 'Дневник малыша':
      return const NewbornTrackerScreen();
    case 'Календарь прививок':
      return const VaccinationCalendarScreen();
    case 'Дневник самочувствия':
      return const DailyLogScreen();
    case 'Отчёт для врача':
      return const DoctorReportScreen();
    case 'Счётчик схваток':
      return const ContractionScreen();
    case 'Счётчик толчков':
      return const KickCounterScreen();
    case 'Монитор веса мамы':
      return const WeightMonitorScreen();
    case 'Чеклисты':
    case 'Подготовка к роддому':
      return ChecklistScreen(title: title);
    case 'Выбор имени для ребёнка':
      return const BabyNamesScreen();
    case 'Группа крови младенца':
      return const BloodTypeScreen();
    case 'Расшифровка УЗИ':
      return const UltrasoundScreen();
    case 'Что можно есть':
      return const AllowedScreen(title: 'Что можно есть', kind: 'food');
    case 'Что можно делать':
      return const AllowedScreen(title: 'Что можно делать', kind: 'activity');
    case 'Календарь беременности':
      return const PregnancyCalendarScreen();
    case 'Календарь развития ребёнка':
      return const ChildGrowthScreen();
    default:
      return _ServiceStub(title: title);
  }
}

class _Service {
  const _Service(this.title, this.icon, this.color);
  final String title;
  final IconData icon;
  final Color color;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service});
  final _Service service;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: service.color,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _screenFor(service.title)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(service.icon, color: Colors.black87),
              ),
              const Spacer(),
              Text(service.title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Временная заглушка для сервиса «в разработке».
class _ServiceStub extends StatelessWidget {
  const _ServiceStub({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction, size: 64, color: Colors.black26),
              SizedBox(height: 16),
              Text('Скоро здесь появится этот сервис',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
