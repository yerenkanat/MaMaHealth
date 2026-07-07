import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../engagement/engagement_service.dart';

/// Монитор прибавки веса мамы: график прибавки (кг) по неделям + рекомендуемый коридор.
class WeightMonitorScreen extends StatefulWidget {
  const WeightMonitorScreen({super.key});

  @override
  State<WeightMonitorScreen> createState() => _WeightMonitorScreenState();
}

class _WeightMonitorScreenState extends State<WeightMonitorScreen> {
  // Замеры (неделя, прибавка в кг) — грузятся из EngagementService.
  final List<MapEntry<int, double>> _points = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<EngagementService>().weight();
      if (!mounted) return;
      setState(() {
        _points
          ..clear()
          ..addAll(data.map((p) => MapEntry(p.week, p.gainKg)));
        _points.sort((a, b) => a.key.compareTo(b.key));
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Рекомендуемый коридор прибавки (нормальный ИМТ), опорные точки.
  static const _refWeeks = [0, 13, 20, 28, 40];
  static const _refMin = [0.0, 0.5, 3.5, 7.0, 11.5];
  static const _refMax = [0.0, 2.0, 6.0, 10.5, 16.0];

  List<FlSpot> _ref(List<double> v) =>
      [for (var i = 0; i < _refWeeks.length; i++) FlSpot(_refWeeks[i].toDouble(), v[i])];

  double get _lastGain => _points.isEmpty ? 0 : _points.last.value;

  Future<void> _add() async {
    final svc = context.read<EngagementService>();
    final res = await showDialog<MapEntry<int, double>>(
      context: context,
      builder: (_) => const _AddWeightDialog(),
    );
    if (res != null) {
      setState(() {
        _points
          ..removeWhere((e) => e.key == res.key)
          ..add(res);
        _points.sort((a, b) => a.key.compareTo(b.key));
      });
      try {
        await svc.saveWeight(res.key, res.value);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось сохранить замер')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Монитор веса')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Замер'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Текущая прибавка: ',
                    style: TextStyle(fontSize: 16)),
                Text('${_lastGain.toStringAsFixed(1)} кг',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 40,
                  minY: 0,
                  maxY: 18,
                  gridData: const FlGridData(
                      show: true, horizontalInterval: 3, verticalInterval: 5),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('неделя', style: TextStyle(fontSize: 11)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        reservedSize: 24,
                        getTitlesWidget: (v, m) =>
                            Text('${v.toInt()}', style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('кг', style: TextStyle(fontSize: 11)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 3,
                        reservedSize: 28,
                        getTitlesWidget: (v, m) =>
                            Text('${v.toInt()}', style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _ref(_refMax),
                      isCurved: true,
                      color: Colors.green.shade200,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: _ref(_refMin),
                      isCurved: true,
                      color: Colors.green.shade200,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: [
                        for (final p in _points) FlSpot(p.key.toDouble(), p.value)
                      ],
                      isCurved: true,
                      color: scheme.primary,
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Зелёный коридор — рекомендуемая прибавка (норм. ИМТ)',
                style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
          ),
        ],
      ),
    );
  }
}

class _AddWeightDialog extends StatefulWidget {
  const _AddWeightDialog();

  @override
  State<_AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends State<_AddWeightDialog> {
  final _formKey = GlobalKey<FormState>();
  final _week = TextEditingController();
  final _gain = TextEditingController();

  @override
  void dispose() {
    _week.dispose();
    _gain.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(MapEntry(
      int.parse(_week.text.trim()),
      double.parse(_gain.text.trim().replaceAll(',', '.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый замер'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _week,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Неделя (0–42)'),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 0 || n > 42) return '0–42';
                return null;
              },
            ),
            TextFormField(
              controller: _gain,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Прибавка, кг'),
              validator: (v) {
                final n = double.tryParse((v?.trim() ?? '').replaceAll(',', '.'));
                if (n == null || n < 0 || n > 30) return '0–30';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
        FilledButton(onPressed: _submit, child: const Text('Добавить')),
      ],
    );
  }
}
