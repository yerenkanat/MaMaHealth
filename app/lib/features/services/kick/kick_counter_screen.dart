import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../engagement/engagement_service.dart';
import '../../kick_counter/widgets/kick_heart_button.dart';

/// Экран «Счётчик толчков»: сессия подсчёта шевелений с таймером,
/// сохранением в бэкенд и историей последних сессий.
class KickCounterScreen extends StatefulWidget {
  const KickCounterScreen({super.key});

  @override
  State<KickCounterScreen> createState() => _KickCounterScreenState();
}

class _KickCounterScreenState extends State<KickCounterScreen> {
  int _count = 0;
  DateTime? _startedAt; // момент первого толчка в сессии
  bool _saving = false;
  Future<List<KickSession>>? _history;

  @override
  void initState() {
    super.initState();
    _reloadHistory();
  }

  void _reloadHistory() {
    final future = context.read<EngagementService>().kicks();
    setState(() {
      _history = future;
    });
  }

  void _onKick() {
    setState(() {
      _startedAt ??= DateTime.now();
      _count++;
    });
  }

  Duration get _elapsed =>
      _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  Future<void> _save() async {
    if (_count == 0 || _saving) return;
    final svc = context.read<EngagementService>();
    final seconds = _elapsed.inSeconds;
    setState(() => _saving = true);
    try {
      await svc.saveKick(_count, seconds);
      if (!mounted) return;
      setState(() {
        _count = 0;
        _startedAt = null;
        _saving = false;
      });
      _reloadHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сессия сохранена')),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить сессию')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Счётчик толчков')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          const Center(
            child: Text('Нажимайте при каждом шевелении малыша',
                style: TextStyle(color: Colors.black54)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _startedAt == null
                  ? '10 шевелений за ~2 часа — норма'
                  : 'В этой сессии: $_count · ${_fmt(_elapsed)}',
              style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: KickHeartButton(count: _count, onKick: _onKick),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _count == 0
                    ? null
                    : () => setState(() {
                          _count = 0;
                          _startedAt = null;
                        }),
                child: const Text('Сбросить'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _count == 0 || _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Сохранить'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('История сессий',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          _HistoryList(future: _history),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$mм ${s.toString().padLeft(2, '0')}с';
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.future});
  final Future<List<KickSession>>? future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<KickSession>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text('Пока нет сохранённых сессий',
                style: TextStyle(color: AppColors.inkMuted)),
          );
        }
        return Column(
          children: [
            for (final k in items)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFBE0EC),
                  child: Icon(Icons.favorite, color: Color(0xFFD53A5E)),
                ),
                title: Text('${k.count} шевелений'),
                subtitle: Text(_KickCounterScreenState._fmt(
                    Duration(seconds: k.durationSeconds))),
                trailing: Text(_date(k.createdAt),
                    style: const TextStyle(color: AppColors.inkMuted, fontSize: 13)),
              ),
          ],
        );
      },
    );
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
