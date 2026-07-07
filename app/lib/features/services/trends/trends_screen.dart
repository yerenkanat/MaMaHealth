import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../engagement/engagement_service.dart';

/// «Мои тренды» — превращает накопленные логи в инсайты:
/// настроение за 14 дней, частые симптомы, динамика веса, активность малыша.
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsData {
  const _TrendsData({required this.daily, required this.kicks, required this.weight});
  final List<DailyLog> daily;
  final List<KickSession> kicks;
  final List<WeightPoint> weight;
}

const _moodScore = <String, double>{
  'bad': 1,
  'low': 2,
  'ok': 3,
  'good': 4,
  'great': 5,
};

const _moodEmojiByScore = <int, String>{
  1: '😣',
  2: '😕',
  3: '😐',
  4: '🙂',
  5: '😄',
};

const _symptomRu = <String, String>{
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

class _TrendsScreenState extends State<TrendsScreen> {
  Future<_TrendsData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TrendsData> _load() async {
    final svc = context.read<EngagementService>();
    final r = await Future.wait([svc.dailyLogs(), svc.kicks(), svc.weight()]);
    return _TrendsData(
      daily: r[0] as List<DailyLog>,
      kicks: r[1] as List<KickSession>,
      weight: r[2] as List<WeightPoint>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои тренды')),
      body: FutureBuilder<_TrendsData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('Не удалось загрузить: ${snap.error}'));
          }
          final d = snap.data!;
          final hasAny =
              d.daily.isNotEmpty || d.kicks.isNotEmpty || d.weight.isNotEmpty;
          if (!hasAny) {
            return const _Empty();
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MoodTrendCard(daily: d.daily),
              const SizedBox(height: 12),
              _SymptomsCard(daily: d.daily),
              const SizedBox(height: 12),
              _WeightCard(weight: d.weight),
              const SizedBox(height: 12),
              _KicksCard(kicks: d.kicks),
            ],
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insights, size: 64, color: Colors.black26),
              SizedBox(height: 16),
              Text(
                'Пока нет данных для трендов.\nЗаполняйте дневник самочувствия и трекеры — '
                'здесь появятся графики.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

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
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primaryDeep),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MoodTrendCard extends StatelessWidget {
  const _MoodTrendCard({required this.daily});
  final List<DailyLog> daily;

  @override
  Widget build(BuildContext context) {
    // logs приходят DESC; берём последние 14 и переворачиваем в хронологию.
    final recent = daily
        .where((l) => l.mood != null && _moodScore.containsKey(l.mood))
        .take(14)
        .toList()
        .reversed
        .toList();

    if (recent.length < 2) {
      return _Card(
        title: 'Настроение',
        icon: Icons.mood,
        child: Text(
          recent.isEmpty
              ? 'Отметьте настроение хотя бы за 2 дня, чтобы увидеть тренд.'
              : 'Сегодня: ${_moodEmojiByScore[_moodScore[recent.first.mood]!.toInt()]}',
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < recent.length; i++)
        FlSpot(i.toDouble(), _moodScore[recent[i].mood]!),
    ];
    final avg = spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;

    return _Card(
      title: 'Настроение за ${recent.length} дн.',
      icon: Icons.mood,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('В среднем: ${_moodEmojiByScore[avg.round()]} ',
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: 1,
                maxY: 5,
                gridData: const FlGridData(show: true, horizontalInterval: 1),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 32,
                      getTitlesWidget: (v, m) => Text(
                          _moodEmojiByScore[v.toInt()] ?? '',
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF8B7BF0),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF8B7BF0).withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomsCard extends StatelessWidget {
  const _SymptomsCard({required this.daily});
  final List<DailyLog> daily;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final l in daily) {
      for (final s in l.symptoms) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = top.isEmpty ? 1 : top.first.value;

    return _Card(
      title: 'Частые симптомы',
      icon: Icons.healing_outlined,
      child: top.isEmpty
          ? const Text('Симптомы пока не отмечались.',
              style: TextStyle(color: Colors.black54))
          : Column(
              children: [
                for (final e in top.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 130,
                          child: Text(_symptomRu[e.key] ?? e.key,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: e.value / maxCount,
                              minHeight: 12,
                              backgroundColor: const Color(0xFFF1EEF7),
                              color: const Color(0xFFFF9E7A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${e.value}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.weight});
  final List<WeightPoint> weight;

  @override
  Widget build(BuildContext context) {
    if (weight.isEmpty) {
      return const _Card(
        title: 'Вес',
        icon: Icons.monitor_weight_outlined,
        child: Text('Нет замеров веса.',
            style: TextStyle(color: Colors.black54)),
      );
    }
    final sorted = [...weight]..sort((a, b) => a.week.compareTo(b.week));
    final last = sorted.last;
    final first = sorted.first;
    final delta = last.gainKg - first.gainKg;
    return _Card(
      title: 'Вес',
      icon: Icons.monitor_weight_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Текущая прибавка: +${last.gainKg.toStringAsFixed(1)} кг '
              '(нед. ${last.week})'),
          const SizedBox(height: 4),
          Text(
              'Динамика за период: +${delta.toStringAsFixed(1)} кг '
              'за ${last.week - first.week} нед.',
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      ),
    );
  }
}

class _KicksCard extends StatelessWidget {
  const _KicksCard({required this.kicks});
  final List<KickSession> kicks;

  @override
  Widget build(BuildContext context) {
    if (kicks.isEmpty) {
      return const _Card(
        title: 'Активность малыша',
        icon: Icons.favorite_outline,
        child: Text('Нет сессий подсчёта шевелений.',
            style: TextStyle(color: Colors.black54)),
      );
    }
    final total = kicks.fold<int>(0, (s, k) => s + k.count);
    final avg = total / kicks.length;
    return _Card(
      title: 'Активность малыша',
      icon: Icons.favorite_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Сессий подсчёта: ${kicks.length}'),
          const SizedBox(height: 4),
          Text('В среднем ${avg.toStringAsFixed(1)} шевелений за сессию',
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      ),
    );
  }
}
