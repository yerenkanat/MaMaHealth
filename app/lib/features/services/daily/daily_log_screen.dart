import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../engagement/engagement_service.dart';

/// Дневник самочувствия (Flo-style): настроение дня + симптомы + заметка,
/// одна запись на день (upsert), плюс лента прошлых дней.
class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

const _moods = <(String, String, String)>[
  ('great', '😄', 'Отлично'),
  ('good', '🙂', 'Хорошо'),
  ('ok', '😐', 'Нормально'),
  ('low', '😕', 'Так себе'),
  ('bad', '😣', 'Плохо'),
];

const _symptomCatalog = <(String, String)>[
  ('nausea', 'Тошнота'),
  ('fatigue', 'Усталость'),
  ('headache', 'Головная боль'),
  ('backache', 'Боль в спине'),
  ('cravings', 'Тяга к еде'),
  ('swelling', 'Отёки'),
  ('heartburn', 'Изжога'),
  ('insomnia', 'Бессонница'),
  ('cramps', 'Спазмы'),
  ('dizziness', 'Головокружение'),
];

String _symptomLabel(String key) =>
    _symptomCatalog.firstWhere((e) => e.$1 == key, orElse: () => (key, key)).$2;

String _moodEmoji(String key) =>
    _moods.firstWhere((e) => e.$1 == key, orElse: () => (key, '•', key)).$2;

class _DailyLogScreenState extends State<DailyLogScreen> {
  String? _mood;
  final Set<String> _symptoms = {};
  final _note = TextEditingController();
  bool _saving = false;
  Future<List<DailyLog>>? _history;

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final future = context.read<EngagementService>().dailyLogs();
    setState(() {
      _history = future;
    });
    try {
      final logs = await future;
      final today = logs.where((l) => l.date == _today).firstOrNull;
      if (today != null && mounted) {
        setState(() {
          _mood = today.mood;
          _symptoms
            ..clear()
            ..addAll(today.symptoms);
          _note.text = today.note ?? '';
        });
      }
    } catch (_) {
      // офлайн — оставляем пустую форму
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final svc = context.read<EngagementService>();
    setState(() => _saving = true);
    try {
      await svc.saveDaily(_today, _mood, _symptoms.toList(), _note.text.trim());
      final future = svc.dailyLogs();
      if (!mounted) return;
      setState(() {
        _history = future;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись сохранена')),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дневник самочувствия')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Как ты себя чувствуешь сегодня?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final m in _moods)
                _MoodButton(
                  emoji: m.$2,
                  label: m.$3,
                  selected: _mood == m.$1,
                  onTap: () => setState(() => _mood = m.$1),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Симптомы',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _symptomCatalog)
                FilterChip(
                  label: Text(s.$2),
                  selected: _symptoms.contains(s.$1),
                  onSelected: (on) => setState(() {
                    if (on) {
                      _symptoms.add(s.$1);
                    } else {
                      _symptoms.remove(s.$1);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _note,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Заметка (необязательно)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Сохранить сегодня'),
          ),
          const SizedBox(height: 28),
          const Text('История',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _HistoryList(future: _history, today: _today),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? const Color(0xFFE7E0FB)
                  : const Color(0xFFF3F4FB),
              border: selected
                  ? Border.all(color: const Color(0xFF6A4BD0), width: 2)
                  : null,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: selected ? const Color(0xFF6A4BD0) : Colors.black45,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.future, required this.today});
  final Future<List<DailyLog>>? future;
  final String today;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DailyLog>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Пока нет записей', style: TextStyle(color: Colors.black45)),
          );
        }
        return Column(
          children: [
            for (final l in items)
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: Text(l.mood == null ? '•' : _moodEmoji(l.mood!),
                      style: const TextStyle(fontSize: 26)),
                  title: Text(l.date == today ? 'Сегодня' : l.date),
                  subtitle: Text(
                    [
                      if (l.symptoms.isNotEmpty)
                        l.symptoms.map(_symptomLabel).join(', '),
                      if (l.note != null && l.note!.isNotEmpty) l.note!,
                    ].join(' · '),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
