import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../engagement/engagement_service.dart';

/// «Дневник малыша» — быстрый лог кормлений, сна и подгузников +
/// сводка за сегодня и лента последних событий. Детская сторона USP.
class NewbornTrackerScreen extends StatefulWidget {
  const NewbornTrackerScreen({super.key});

  @override
  State<NewbornTrackerScreen> createState() => _NewbornTrackerScreenState();
}

class _NewbornTrackerScreenState extends State<NewbornTrackerScreen> {
  Future<List<BabyEvent>>? _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final future = context.read<EngagementService>().babyEvents();
    setState(() => _future = future);
  }

  Future<void> _log(String type, String? detail) async {
    if (_saving) return;
    final svc = context.read<EngagementService>();
    setState(() => _saving = true);
    HapticFeedback.selectionClick();
    try {
      await svc.saveBabyEvent(type, detail);
      if (!mounted) return;
      _reload();
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Записано: ${_title(type, detail)}')),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось записать')),
        );
      }
    }
  }

  Future<void> _feed() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => const _FeedSheet(),
    );
    if (choice != null) _log('feed', choice);
  }

  Future<void> _diaper() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => const _DiaperSheet(),
    );
    if (choice != null) _log('diaper', choice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дневник малыша')),
      body: FutureBuilder<List<BabyEvent>>(
        future: _future,
        builder: (context, snap) {
          final events = snap.data ?? const <BabyEvent>[];
          final today = DateTime.now();
          final todays = events
              .where((e) =>
                  e.happenedAt.year == today.year &&
                  e.happenedAt.month == today.month &&
                  e.happenedAt.day == today.day)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TodaySummary(events: todays),
              const SizedBox(height: 16),
              Row(
                children: [
                  _QuickButton(
                    icon: Icons.restaurant,
                    label: 'Покормила',
                    color: const Color(0xFFFDE7D6),
                    onTap: _saving ? null : _feed,
                  ),
                  const SizedBox(width: 10),
                  _QuickButton(
                    icon: Icons.bedtime_outlined,
                    label: 'Уснул',
                    color: const Color(0xFFE7E0FB),
                    onTap: _saving ? null : () => _log('sleep', null),
                  ),
                  const SizedBox(width: 10),
                  _QuickButton(
                    icon: Icons.baby_changing_station,
                    label: 'Подгузник',
                    color: const Color(0xFFDCEFFB),
                    onTap: _saving ? null : _diaper,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Сегодня',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (snap.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (todays.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Сегодня событий пока нет.',
                      style: TextStyle(color: Colors.black45)),
                )
              else
                for (final e in todays) _EventTile(event: e),
            ],
          );
        },
      ),
    );
  }

  static String _title(String type, String? detail) {
    switch (type) {
      case 'feed':
        return detail == 'bottle' ? 'Кормление (бутылочка)' : 'Кормление (грудь)';
      case 'sleep':
        return 'Сон';
      case 'diaper':
        return detail == 'dirty' ? 'Подгузник (грязный)' : 'Подгузник (мокрый)';
      default:
        return type;
    }
  }
}

String _eventTitle(BabyEvent e) =>
    _NewbornTrackerScreenState._title(e.type, e.detail);

IconData _eventIcon(String type) {
  switch (type) {
    case 'feed':
      return Icons.restaurant;
    case 'sleep':
      return Icons.bedtime_outlined;
    default:
      return Icons.baby_changing_station;
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.events});
  final List<BabyEvent> events;

  @override
  Widget build(BuildContext context) {
    final feeds = events.where((e) => e.type == 'feed').length;
    final sleeps = events.where((e) => e.type == 'sleep').length;
    final diapers = events.where((e) => e.type == 'diaper').length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(icon: Icons.restaurant, value: feeds, label: 'кормлений'),
          _Stat(icon: Icons.bedtime_outlined, value: sleeps, label: 'снов'),
          _Stat(
              icon: Icons.baby_changing_station,
              value: diapers,
              label: 'подгузн.'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6A4BD0)),
        const SizedBox(height: 6),
        Text('$value',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black45)),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Icon(icon, color: Colors.black87),
                const SizedBox(height: 8),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final BabyEvent event;

  String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF1EEF7),
          child: Icon(_eventIcon(event.type), color: const Color(0xFF6A4BD0)),
        ),
        title: Text(_eventTitle(event)),
        trailing: Text(_time(event.happenedAt),
            style: const TextStyle(color: Colors.black45)),
      ),
    );
  }
}

class _FeedSheet extends StatelessWidget {
  const _FeedSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Тип кормления',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          ListTile(
            leading: const Icon(Icons.child_care),
            title: const Text('Грудь'),
            onTap: () => Navigator.pop(context, 'breast'),
          ),
          ListTile(
            leading: const Icon(Icons.local_drink_outlined),
            title: const Text('Бутылочка'),
            onTap: () => Navigator.pop(context, 'bottle'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DiaperSheet extends StatelessWidget {
  const _DiaperSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Подгузник',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          ListTile(
            leading: const Icon(Icons.water_drop_outlined),
            title: const Text('Мокрый'),
            onTap: () => Navigator.pop(context, 'wet'),
          ),
          ListTile(
            leading: const Icon(Icons.eco_outlined),
            title: const Text('Грязный'),
            onTap: () => Navigator.pop(context, 'dirty'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
