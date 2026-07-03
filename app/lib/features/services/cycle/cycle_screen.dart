import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../engagement/engagement_service.dart';

/// «Мой цикл» — трекинг месячных как в Flo: прогноз следующих,
/// фертильное окно и овуляция, календарь фаз, история циклов.
class CycleScreen extends StatefulWidget {
  const CycleScreen({super.key});

  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

enum _Phase { none, period, predictedPeriod, fertile, ovulation }

class _CycleStats {
  const _CycleStats({
    required this.avgCycle,
    required this.avgPeriodLen,
    required this.lastStart,
    required this.nextStart,
    required this.ovulation,
    required this.fertileStart,
    required this.fertileEnd,
  });

  final int avgCycle;
  final int avgPeriodLen;
  final DateTime? lastStart;
  final DateTime? nextStart;
  final DateTime? ovulation;
  final DateTime? fertileStart;
  final DateTime? fertileEnd;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class _CycleScreenState extends State<CycleScreen> {
  List<CyclePeriod> _periods = [];
  List<DailyLog> _daily = [];
  bool _loading = true;
  late DateTime _month; // первый день видимого месяца

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _load();
  }

  Future<void> _load() async {
    final svc = context.read<EngagementService>();
    try {
      final results = await Future.wait([svc.cycles(), svc.dailyLogs()]);
      if (!mounted) return;
      setState(() {
        _periods = results[0] as List<CyclePeriod>;
        _daily = results[1] as List<DailyLog>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  _CycleStats _stats() {
    // periods отсортированы DESC; для расчётов нужен ASC
    final asc = [..._periods]..sort((a, b) => a.start.compareTo(b.start));
    if (asc.isEmpty) {
      return const _CycleStats(
        avgCycle: 28,
        avgPeriodLen: 5,
        lastStart: null,
        nextStart: null,
        ovulation: null,
        fertileStart: null,
        fertileEnd: null,
      );
    }
    // средняя длина цикла по разнице между началами
    final gaps = <int>[];
    for (var i = 1; i < asc.length; i++) {
      gaps.add(asc[i].start.difference(asc[i - 1].start).inDays);
    }
    var avgCycle = gaps.isEmpty
        ? 28
        : (gaps.reduce((a, b) => a + b) / gaps.length).round();
    avgCycle = avgCycle.clamp(21, 35);

    final lens = <int>[
      for (final p in asc)
        if (p.end != null) p.end!.difference(p.start).inDays + 1,
    ];
    final avgPeriodLen = lens.isEmpty
        ? 5
        : (lens.reduce((a, b) => a + b) / lens.length).round().clamp(2, 10);

    final lastStart = _dateOnly(asc.last.start);
    final nextStart = lastStart.add(Duration(days: avgCycle));
    final ovulation = nextStart.subtract(const Duration(days: 14));
    final fertileStart = ovulation.subtract(const Duration(days: 4));
    final fertileEnd = ovulation.add(const Duration(days: 1));

    return _CycleStats(
      avgCycle: avgCycle,
      avgPeriodLen: avgPeriodLen,
      lastStart: lastStart,
      nextStart: nextStart,
      ovulation: ovulation,
      fertileStart: fertileStart,
      fertileEnd: fertileEnd,
    );
  }

  _Phase _phaseFor(DateTime day, _CycleStats s) {
    final d = _dateOnly(day);
    // залогированные месячные
    for (final p in _periods) {
      final start = _dateOnly(p.start);
      final end = p.end == null
          ? start.add(Duration(days: s.avgPeriodLen - 1))
          : _dateOnly(p.end!);
      if (!d.isBefore(start) && !d.isAfter(end)) return _Phase.period;
    }
    if (s.ovulation != null && d == s.ovulation) return _Phase.ovulation;
    if (s.fertileStart != null &&
        !d.isBefore(s.fertileStart!) &&
        !d.isAfter(s.fertileEnd!)) {
      return _Phase.fertile;
    }
    if (s.nextStart != null) {
      final predEnd = s.nextStart!.add(Duration(days: s.avgPeriodLen - 1));
      if (!d.isBefore(s.nextStart!) && !d.isAfter(predEnd)) {
        return _Phase.predictedPeriod;
      }
    }
    return _Phase.none;
  }

  static const _symptomRu = <String, String>{
    'nausea': 'Тошнота',
    'fatigue': 'Усталость',
    'headache': 'Головная боль',
    'backache': 'Боль в спине',
    'cravings': 'Тяга к еде',
    'swelling': 'Отёки',
    'heartburn': 'Изжога',
    'insomnia': 'Бессонница',
    'cramps': 'Спазмы',
    'dizziness': 'Головокружение',
  };

  /// Симптомы, чаще всего отмечаемые в лютеиновой (пред-менструальной) фазе.
  List<MapEntry<String, int>> _pmsSymptoms(_CycleStats s) {
    if (_periods.isEmpty || _daily.isEmpty) return const [];
    final startsAsc = _periods.map((p) => _dateOnly(p.start)).toList()..sort();
    final counts = <String, int>{};
    for (final log in _daily) {
      final d = DateTime.tryParse(log.date);
      if (d == null || log.symptoms.isEmpty) continue;
      DateTime? base;
      for (final st in startsAsc) {
        if (!st.isAfter(d)) {
          base = st;
        } else {
          break;
        }
      }
      if (base == null) continue;
      final cycleDay = d.difference(base).inDays + 1;
      if (cycleDay >= s.avgCycle - 5 && cycleDay <= s.avgCycle + 2) {
        for (final sym in log.symptoms) {
          counts[sym] = (counts[sym] ?? 0) + 1;
        }
      }
    }
    final list = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  Future<void> _logPeriod() async {
    final now = DateTime.now();
    final svc = context.read<EngagementService>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 400)),
      lastDate: now,
      helpText: 'Отметьте дни месячных',
    );
    if (range == null) return;
    try {
      await svc.saveCycle(range.start, range.end);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Месячные отмечены')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мой цикл')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logPeriod,
        icon: const Icon(Icons.water_drop),
        label: const Text('Отметить месячные'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final s = _stats();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _SummaryCard(stats: s),
        const SizedBox(height: 16),
        _MonthCalendar(
          month: _month,
          phaseFor: (d) => _phaseFor(d, s),
          onPrev: () => setState(
              () => _month = DateTime(_month.year, _month.month - 1, 1)),
          onNext: () => setState(
              () => _month = DateTime(_month.year, _month.month + 1, 1)),
        ),
        const SizedBox(height: 16),
        const _Legend(),
        const SizedBox(height: 16),
        _PmsCard(symptoms: _pmsSymptoms(s), label: (k) => _symptomRu[k] ?? k),
        const SizedBox(height: 16),
        if (_periods.isNotEmpty) _History(periods: _periods),
      ],
    );
  }
}

class _PmsCard extends StatelessWidget {
  const _PmsCard({required this.symptoms, required this.label});
  final List<MapEntry<String, int>> symptoms;
  final String Function(String) label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, size: 20, color: Color(0xFFFF6B81)),
              SizedBox(width: 8),
              Text('Симптомы перед месячными',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          if (symptoms.isEmpty)
            const Text(
              'Отмечайте самочувствие в дневнике — здесь появятся ваши ПМС-паттерны.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in symptoms.take(5))
                  Chip(
                    backgroundColor: const Color(0xFFFFE0E6),
                    side: BorderSide.none,
                    label: Text('${label(e.key)} · ${e.value}',
                        style: const TextStyle(fontSize: 13)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats});
  final _CycleStats stats;

  @override
  Widget build(BuildContext context) {
    final now = _dateOnly(DateTime.now());
    String big;
    String sub;
    if (stats.lastStart == null) {
      big = 'Нет данных';
      sub = 'Отметьте месячные, чтобы увидеть прогноз';
    } else {
      final cycleDay = now.difference(stats.lastStart!).inDays + 1;
      big = 'День цикла: $cycleDay';
      final toNext = stats.nextStart!.difference(now).inDays;
      if (toNext > 0) {
        sub = 'Следующие месячные через $toNext дн.';
      } else if (toNext == 0) {
        sub = 'Месячные ожидаются сегодня';
      } else {
        sub = 'Задержка ${-toNext} дн.';
      }
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8FA3), Color(0xFFFFB3A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(big,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: Colors.white)),
          if (stats.fertileStart != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.eco, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Фертильное окно: ${_fmtShort(stats.fertileStart!)} – ${_fmtShort(stats.fertileEnd!)}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Средний цикл: ${stats.avgCycle} дн.',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  static String _fmtShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.phaseFor,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final _Phase Function(DateTime) phaseFor;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _monthNames = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];
  static const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Пн
    final today = _dateOnly(DateTime.now());

    final cells = <Widget>[];
    for (var i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      cells.add(_DayCell(
        day: day,
        phase: phaseFor(date),
        isToday: _dateOnly(date) == today,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Text('${_monthNames[month.month - 1]} ${month.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                  onPressed: onNext, icon: const Icon(Icons.chevron_right)),
            ],
          ),
          Row(
            children: [
              for (final w in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(w,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black45)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.phase, required this.isToday});
  final int day;
  final _Phase phase;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    Color? bg;
    Color fg = Colors.black87;
    switch (phase) {
      case _Phase.period:
        bg = const Color(0xFFFF6B81);
        fg = Colors.white;
        break;
      case _Phase.predictedPeriod:
        bg = const Color(0xFFFFD5DC);
        break;
      case _Phase.ovulation:
        bg = const Color(0xFF3EC98A);
        fg = Colors.white;
        break;
      case _Phase.fertile:
        bg = const Color(0xFFD5F2E4);
        break;
      case _Phase.none:
        bg = null;
    }
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: const Color(0xFF6A4BD0), width: 2)
              : null,
        ),
        child: Text('$day', style: TextStyle(color: fg, fontSize: 13)),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(t, style: const TextStyle(fontSize: 12)),
          ],
        );
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        item(const Color(0xFFFF6B81), 'Месячные'),
        item(const Color(0xFFFFD5DC), 'Прогноз'),
        item(const Color(0xFF3EC98A), 'Овуляция'),
        item(const Color(0xFFD5F2E4), 'Фертильные дни'),
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.periods});
  final List<CyclePeriod> periods;

  @override
  Widget build(BuildContext context) {
    // periods DESC; длина цикла = разница до предыдущего начала
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('История циклов',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (var i = 0; i < periods.length; i++)
          Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFE0E6),
                child: Icon(Icons.water_drop, color: Color(0xFFFF6B81)),
              ),
              title: Text(periods[i].end == null
                  ? 'С ${fmt(periods[i].start)}'
                  : '${fmt(periods[i].start)} – ${fmt(periods[i].end!)}'),
              subtitle: i + 1 < periods.length
                  ? Text(
                      'Цикл: ${periods[i].start.difference(periods[i + 1].start).inDays} дн.')
                  : null,
            ),
          ),
      ],
    );
  }
}
