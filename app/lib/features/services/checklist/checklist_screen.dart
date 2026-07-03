import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../engagement/engagement_service.dart';

/// Чеклист (в роддом / подготовка) с прогрессом и отметками.
class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key, required this.title});

  final String title;

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  static const _sections = <String, List<String>>{
    'Документы': [
      'Паспорт и копия',
      'Обменная карта',
      'Полис / направление',
      'Родовой сертификат',
    ],
    'Для мамы': [
      'Халат и сорочка',
      'Тапочки моющиеся',
      'Гигиенические прокладки',
      'Средства гигиены',
      'Зарядка для телефона',
    ],
    'Для малыша': [
      'Подгузники (для новорождённых)',
      'Пелёнки / боди',
      'Шапочка и носочки',
      'Влажные салфетки',
    ],
  };

  final Set<String> _checked = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items =
          await context.read<EngagementService>().checklistState(widget.title);
      if (!mounted) return;
      setState(() {
        _checked
          ..clear()
          ..addAll(items);
      });
    } catch (_) {
      // офлайн — начинаем без отметок
    }
  }

  Future<void> _persist() async {
    try {
      await context
          .read<EngagementService>()
          .saveChecklistState(widget.title, _checked.toList());
    } catch (_) {
      // молча — локальное состояние уже обновлено
    }
  }

  int get _total => _sections.values.fold(0, (s, l) => s + l.length);
  int get _done => _checked.length;

  @override
  Widget build(BuildContext context) {
    final progress = _total == 0 ? 0.0 : _done / _total;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Готово $_done из $_total',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: progress, minHeight: 10),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final entry in _sections.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(entry.key,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  for (final item in entry.value)
                    CheckboxListTile(
                      value: _checked.contains(item),
                      title: Text(item),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _checked.add(item);
                          } else {
                            _checked.remove(item);
                          }
                        });
                        _persist();
                      },
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
