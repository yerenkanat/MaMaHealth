import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/growth_measurement.dart';
import '../cubit/growth_cubit.dart';
import 'growth_chart.dart';

/// Экран роста для режима ребёнка: график ВОЗ + добавление замеров.
class GrowthSection extends StatelessWidget {
  const GrowthSection({super.key, required this.gender});

  final String gender;

  // Демо-замеры, чтобы график не был пустым.
  static const _demoSeed = [
    GrowthMeasurement(ageMonths: 0, weightKg: 3.4, heightCm: 51),
    GrowthMeasurement(ageMonths: 1, weightKg: 4.4, heightCm: 55),
    GrowthMeasurement(ageMonths: 2, weightKg: 5.3, heightCm: 58),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GrowthCubit(List.of(_demoSeed)),
      child: _GrowthBody(gender: gender),
    );
  }
}

class _GrowthBody extends StatelessWidget {
  const _GrowthBody({required this.gender});

  final String gender;

  Future<void> _openAddDialog(BuildContext context) async {
    final cubit = context.read<GrowthCubit>();
    final m = await showDialog<GrowthMeasurement>(
      context: context,
      builder: (_) => const _AddMeasurementDialog(),
    );
    if (m != null) cubit.add(m);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Вес по нормам ВОЗ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const _Legend(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: BlocBuilder<GrowthCubit, List<GrowthMeasurement>>(
              builder: (context, ms) =>
                  GrowthChart(gender: gender, measurements: ms),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Добавить замер'),
            onPressed: () => _openAddDialog(context),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 14,
        children: [
          _dot(const Color(0xFFCFC9F2), 'коридор P3–P97'),
          _dot(AppColors.lavender, 'медиана ВОЗ'),
          _dot(primary, 'ваш малыш'),
        ],
      ),
    );
  }

  Widget _dot(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}

class _AddMeasurementDialog extends StatefulWidget {
  const _AddMeasurementDialog();

  @override
  State<_AddMeasurementDialog> createState() => _AddMeasurementDialogState();
}

class _AddMeasurementDialogState extends State<_AddMeasurementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _monthCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  @override
  void dispose() {
    _monthCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(
      GrowthMeasurement(
        ageMonths: int.parse(_monthCtrl.text.trim()),
        weightKg: double.parse(_weightCtrl.text.trim().replaceAll(',', '.')),
        heightCm: double.parse(_heightCtrl.text.trim().replaceAll(',', '.')),
      ),
    );
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
              controller: _monthCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Возраст, месяцев'),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 0 || n > 24) return '0–24';
                return null;
              },
            ),
            TextFormField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Вес, кг'),
              validator: (v) {
                final n = double.tryParse((v?.trim() ?? '').replaceAll(',', '.'));
                if (n == null || n < 1 || n > 20) return '1–20 кг';
                return null;
              },
            ),
            TextFormField(
              controller: _heightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Рост, см'),
              validator: (v) {
                final n = double.tryParse((v?.trim() ?? '').replaceAll(',', '.'));
                if (n == null || n < 40 || n > 110) return '40–110 см';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Добавить')),
      ],
    );
  }
}
