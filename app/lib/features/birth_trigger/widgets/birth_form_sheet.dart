import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/new_child.dart';

/// Модальная форма регистрации новорождённого («Я родила!»).
/// Возвращает [NewChild] через Navigator.pop при успешной валидации.
class BirthFormSheet extends StatefulWidget {
  const BirthFormSheet({super.key});

  /// Удобный хелпер открытия. Возвращает null, если пользователь отменил.
  static Future<NewChild?> show(BuildContext context) {
    return showModalBottomSheet<NewChild>(
      context: context,
      isScrollControlled: true, // чтобы форма поднималась над клавиатурой
      showDragHandle: true,
      builder: (_) => const BirthFormSheet(),
    );
  }

  @override
  State<BirthFormSheet> createState() => _BirthFormSheetState();
}

class _BirthFormSheetState extends State<BirthFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  String _gender = 'male';
  DateTime _birthDateTime = DateTime.now();

  @override
  void dispose() {
    // Code Reviewer: обязательно закрываем контроллеры.
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDateTime,
      firstDate: now.subtract(const Duration(days: 3)), // роды в пределах пары дней
      lastDate: now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_birthDateTime),
    );
    if (!mounted) return;

    setState(() {
      _birthDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(
      NewChild(
        name: _nameCtrl.text.trim(),
        gender: _gender,
        birthDate: _birthDateTime,
        birthWeightG: int.parse(_weightCtrl.text.trim()),
        birthHeightCm: double.parse(_heightCtrl.text.trim().replaceAll(',', '.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dt = _birthDateTime;
    final dateLabel =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Малыш родился! 🎉',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),

              // Имя
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  prefixIcon: Icon(Icons.child_care),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Укажите имя' : null,
              ),
              const SizedBox(height: 12),

              // Пол
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'male', label: Text('Мальчик'), icon: Icon(Icons.male)),
                  ButtonSegment(
                      value: 'female', label: Text('Девочка'), icon: Icon(Icons.female)),
                ],
                selected: {_gender},
                onSelectionChanged: (s) => setState(() => _gender = s.first),
              ),
              const SizedBox(height: 12),

              // Дата и время рождения
              InkWell(
                onTap: _pickDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Дата и время рождения',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateLabel),
                ),
              ),
              const SizedBox(height: 12),

              // Вес и рост
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Вес, г',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                      validator: (v) {
                        final g = int.tryParse(v?.trim() ?? '');
                        if (g == null) return 'Число';
                        if (g < 500 || g > 6000) return '500–6000 г';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Рост, см',
                        prefixIcon: Icon(Icons.height),
                      ),
                      validator: (v) {
                        final cm = double.tryParse(
                            (v?.trim() ?? '').replaceAll(',', '.'));
                        if (cm == null) return 'Число';
                        if (cm < 20 || cm > 70) return '20–70 см';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                icon: const Icon(Icons.celebration),
                label: const Text('Зарегистрировать'),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
