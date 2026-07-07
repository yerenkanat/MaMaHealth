import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';

import '../../../data/who_growth_data.dart';
import '../../../domain/models/growth_measurement.dart';

/// График «вес-к-возрасту»: коридор нормы ВОЗ (P3–P50–P97) + линия ребёнка.
class GrowthChart extends StatelessWidget {
  const GrowthChart({
    super.key,
    required this.gender,
    required this.measurements,
  });

  final String gender;
  final List<GrowthMeasurement> measurements;

  List<FlSpot> _band(List<double> s) =>
      [for (var m = 0; m < s.length; m++) FlSpot(m.toDouble(), s[m])];

  LineChartBarData _ref(List<double> s, Color c, {bool dashed = false}) =>
      LineChartBarData(
        spots: _band(s),
        isCurved: true,
        color: c,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        dashArray: dashed ? [6, 4] : null,
      );

  @override
  Widget build(BuildContext context) {
    final ref = WhoGrowth.weightForAge(gender);
    final scheme = Theme.of(context).colorScheme;
    final childSpots = [
      for (final m in measurements) FlSpot(m.ageMonths.toDouble(), m.weightKg),
    ]..sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 24,
        minY: 2,
        maxY: 16,
        gridData: const FlGridData(
          show: true,
          horizontalInterval: 2,
          verticalInterval: 3,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('месяц', style: TextStyle(fontSize: 11)),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              reservedSize: 24,
              getTitlesWidget: (v, meta) =>
                  Text('${v.toInt()}', style: const TextStyle(fontSize: 10)),
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('кг', style: TextStyle(fontSize: 11)),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              reservedSize: 28,
              getTitlesWidget: (v, meta) =>
                  Text('${v.toInt()}', style: const TextStyle(fontSize: 10)),
            ),
          ),
        ),
        lineBarsData: [
          _ref(ref.p97, const Color(0xFFCFC9F2)),
          _ref(ref.p3, const Color(0xFFCFC9F2)),
          _ref(ref.p50, AppColors.lavender, dashed: true),
          LineChartBarData(
            spots: childSpots,
            isCurved: true,
            color: scheme.primary,
            barWidth: 4,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
