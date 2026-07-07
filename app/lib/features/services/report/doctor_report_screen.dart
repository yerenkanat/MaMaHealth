import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../engagement/engagement_service.dart';

/// «Отчёт для врача» — сводка всех трекеров (вес, шевеления, схватки,
/// самочувствие) в одном экране + копирование текстом для передачи врачу.
class DoctorReportScreen extends StatefulWidget {
  const DoctorReportScreen({super.key});

  @override
  State<DoctorReportScreen> createState() => _DoctorReportScreenState();
}

class _ReportData {
  const _ReportData({
    required this.me,
    required this.weight,
    required this.kicks,
    required this.contractions,
    required this.daily,
    required this.cycles,
  });

  final MeProfile me;
  final List<WeightPoint> weight;
  final List<KickSession> kicks;
  final List<ContractionLog> contractions;
  final List<DailyLog> daily;
  final List<CyclePeriod> cycles;
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// Строки для отчёта по циклу: последние периоды + средняя длина цикла.
List<String> _cycleLines(List<CyclePeriod> cycles) {
  if (cycles.isEmpty) return const ['нет данных'];
  final asc = [...cycles]..sort((a, b) => a.start.compareTo(b.start));
  final gaps = <int>[];
  for (var i = 1; i < asc.length; i++) {
    gaps.add(asc[i].start.difference(asc[i - 1].start).inDays);
  }
  final lines = <String>[];
  if (gaps.isNotEmpty) {
    final avg = (gaps.reduce((a, b) => a + b) / gaps.length).round();
    lines.add('Средний цикл: $avg дн.');
  }
  for (final c in cycles.take(4)) {
    lines.add(c.end == null
        ? 'с ${_fmtDate(c.start)}'
        : '${_fmtDate(c.start)} – ${_fmtDate(c.end!)}');
  }
  return lines;
}

const _symptomRu = <String, String>{
  'nausea': 'тошнота',
  'fatigue': 'усталость',
  'headache': 'головная боль',
  'backache': 'боль в спине',
  'cravings': 'тяга к еде',
  'swelling': 'отёки',
  'heartburn': 'изжога',
  'insomnia': 'бессонница',
  'cramps': 'спазмы',
  'dizziness': 'головокружение',
};

const _moodRu = <String, String>{
  'great': 'отлично',
  'good': 'хорошо',
  'ok': 'нормально',
  'low': 'так себе',
  'bad': 'плохо',
};

class _DoctorReportScreenState extends State<DoctorReportScreen> {
  Future<_ReportData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ReportData> _load() async {
    final svc = context.read<EngagementService>();
    final results = await Future.wait([
      svc.me(),
      svc.weight(),
      svc.kicks(),
      svc.contractions(),
      svc.dailyLogs(),
      svc.cycles(),
    ]);
    return _ReportData(
      me: results[0] as MeProfile,
      weight: results[1] as List<WeightPoint>,
      kicks: results[2] as List<KickSession>,
      contractions: results[3] as List<ContractionLog>,
      daily: results[4] as List<DailyLog>,
      cycles: results[5] as List<CyclePeriod>,
    );
  }

  String _fmtDur(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$mм ${s.toString().padLeft(2, '0')}с';
  }

  String _buildText(_ReportData d) {
    final b = StringBuffer();
    b.writeln('МЕДИЦИНСКАЯ СВОДКА (MaMa)');
    b.writeln('Пациент: ${d.me.name}${d.me.city == null ? '' : ', ${d.me.city}'}');
    b.writeln('');

    b.writeln('ВЕС (прибавка по неделям):');
    if (d.weight.isEmpty) {
      b.writeln('  нет данных');
    } else {
      for (final w in d.weight) {
        b.writeln('  нед. ${w.week}: +${w.gainKg.toStringAsFixed(1)} кг');
      }
    }
    b.writeln('');

    b.writeln('ШЕВЕЛЕНИЯ (последние сессии):');
    if (d.kicks.isEmpty) {
      b.writeln('  нет данных');
    } else {
      for (final k in d.kicks.take(5)) {
        b.writeln('  ${k.count} шевелений за ${_fmtDur(k.durationSeconds)}');
      }
    }
    b.writeln('');

    b.writeln('СХВАТКИ (последние):');
    if (d.contractions.isEmpty) {
      b.writeln('  нет данных');
    } else {
      for (final c in d.contractions.take(6)) {
        final iv = c.intervalSeconds == null
            ? '—'
            : _fmtDur(c.intervalSeconds!);
        b.writeln('  длит. ${_fmtDur(c.durationSeconds)}, интервал $iv');
      }
    }
    b.writeln('');

    b.writeln('САМОЧУВСТВИЕ (последние дни):');
    if (d.daily.isEmpty) {
      b.writeln('  нет данных');
    } else {
      for (final l in d.daily.take(7)) {
        final mood = l.mood == null ? '' : ' — ${_moodRu[l.mood] ?? l.mood}';
        final sym = l.symptoms.isEmpty
            ? ''
            : ' (${l.symptoms.map((s) => _symptomRu[s] ?? s).join(', ')})';
        b.writeln('  ${l.date}$mood$sym');
      }
    }
    b.writeln('');

    b.writeln('МЕНСТРУАЛЬНЫЙ ЦИКЛ:');
    for (final line in _cycleLines(d.cycles)) {
      b.writeln('  $line');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Отчёт для врача')),
      body: FutureBuilder<_ReportData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('Не удалось загрузить: ${snap.error}'));
          }
          final d = snap.data!;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _Header(me: d.me),
                    const SizedBox(height: 12),
                    _Section(
                      icon: Icons.monitor_weight_outlined,
                      title: 'Вес',
                      lines: d.weight.isEmpty
                          ? const ['нет данных']
                          : d.weight
                              .map((w) =>
                                  'Неделя ${w.week}: +${w.gainKg.toStringAsFixed(1)} кг')
                              .toList(),
                    ),
                    _Section(
                      icon: Icons.favorite_outline,
                      title: 'Шевеления',
                      lines: d.kicks.isEmpty
                          ? const ['нет данных']
                          : d.kicks
                              .take(5)
                              .map((k) =>
                                  '${k.count} шевелений за ${_fmtDur(k.durationSeconds)}')
                              .toList(),
                    ),
                    _Section(
                      icon: Icons.timer_outlined,
                      title: 'Схватки',
                      lines: d.contractions.isEmpty
                          ? const ['нет данных']
                          : d.contractions.take(6).map((c) {
                              final iv = c.intervalSeconds == null
                                  ? '—'
                                  : _fmtDur(c.intervalSeconds!);
                              return 'Длит. ${_fmtDur(c.durationSeconds)}, инт. $iv';
                            }).toList(),
                    ),
                    _Section(
                      icon: Icons.mood,
                      title: 'Самочувствие',
                      lines: d.daily.isEmpty
                          ? const ['нет данных']
                          : d.daily.take(7).map((l) {
                              final mood = l.mood == null
                                  ? ''
                                  : ' — ${_moodRu[l.mood] ?? l.mood}';
                              final sym = l.symptoms.isEmpty
                                  ? ''
                                  : ' (${l.symptoms.map((s) => _symptomRu[s] ?? s).join(', ')})';
                              return '${l.date}$mood$sym';
                            }).toList(),
                    ),
                    _Section(
                      icon: Icons.calendar_today,
                      title: 'Менструальный цикл',
                      lines: _cycleLines(d.cycles),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.copy_all_outlined),
                      label: const Text('Скопировать отчёт'),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: _buildText(d)));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Отчёт скопирован — вставьте врачу')),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.me});
  final MeProfile me;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(me.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            if (me.city != null)
              Text(me.city!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 4),
            const Text('Сводка трекеров MaMa для приёма у врача',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.icon, required this.title, required this.lines});
  final IconData icon;
  final String title;
  final List<String> lines;

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
                Icon(icon, size: 20, color: AppColors.primaryDeep),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• $l',
                    style: const TextStyle(color: Colors.black87)),
              ),
          ],
        ),
      ),
    );
  }
}
