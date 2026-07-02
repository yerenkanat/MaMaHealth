import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Счётчик схваток: тап старт/стоп, длительность и интервал, подсказка «пора в роддом».
class ContractionScreen extends StatefulWidget {
  const ContractionScreen({super.key});

  @override
  State<ContractionScreen> createState() => _ContractionScreenState();
}

class _Contraction {
  _Contraction(this.start, this.duration, this.interval);
  final DateTime start;
  final Duration duration;
  final Duration? interval; // от начала предыдущей схватки
}

class _ContractionScreenState extends State<ContractionScreen> {
  final List<_Contraction> _list = [];
  DateTime? _runningStart;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  bool get _running => _runningStart != null;

  void _toggle() {
    HapticFeedback.mediumImpact();
    if (!_running) {
      _runningStart = DateTime.now();
      _elapsed = Duration.zero;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed = DateTime.now().difference(_runningStart!));
      });
      setState(() {});
    } else {
      _ticker?.cancel();
      final start = _runningStart!;
      final dur = DateTime.now().difference(start);
      final interval = _list.isNotEmpty ? start.difference(_list.first.start) : null;
      setState(() {
        _list.insert(0, _Contraction(start, dur, interval));
        _runningStart = null;
        _elapsed = Duration.zero;
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  /// Правило 5-1-1: ≥6 схваток, средний интервал ≤5 мин, длительность ≥45 с.
  bool get _timeToHospital {
    final recent = _list.take(6).toList();
    if (recent.length < 6) return false;
    final intervals =
        recent.where((c) => c.interval != null).map((c) => c.interval!.inSeconds);
    if (intervals.isEmpty) return false;
    final avgInt = intervals.reduce((a, b) => a + b) / intervals.length;
    final avgDur =
        recent.map((c) => c.duration.inSeconds).reduce((a, b) => a + b) / recent.length;
    return avgInt <= 5 * 60 && avgDur >= 45;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Счётчик схваток')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          if (_timeToHospital)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE0E6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(children: [
                Icon(Icons.local_hospital, color: Color(0xFFD53A5E)),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Схватки регулярные — пора собираться в роддом!',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _running ? const Color(0xFFD53A5E) : const Color(0xFFF48FB1),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_running ? _fmt(_elapsed) : 'Старт',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                    Text(_running ? 'идёт схватка' : 'нажми в начале схватки',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          Expanded(
            child: _list.isEmpty
                ? const Center(child: Text('Схваток пока нет', style: TextStyle(color: Colors.black45)))
                : ListView.separated(
                    itemCount: _list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final c = _list[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${_list.length - i}')),
                        title: Text('Длительность: ${_fmt(c.duration)}'),
                        subtitle: Text(c.interval == null
                            ? 'интервал: —'
                            : 'интервал: ${_fmt(c.interval!)}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
