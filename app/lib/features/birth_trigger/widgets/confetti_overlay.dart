import 'dart:math';
import '../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Полноэкранное конфетти для момента «Я родила!». Само удаляется по завершении.
class ConfettiOverlay {
  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiLayer(onDone: entry.remove),
    );
    overlay.insert(entry);
  }
}

class _ConfettiLayer extends StatefulWidget {
  const _ConfettiLayer({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _Particle {
  _Particle({
    required this.x,
    required this.size,
    required this.color,
    required this.delay,
    required this.drift,
    required this.rot,
    required this.rotSpeed,
  });
  final double x, size, delay, drift, rot, rotSpeed;
  final Color color;
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _rng = Random();
  late final List<_Particle> _parts;

  static const _colors = [
    AppColors.lavender,
    AppColors.mint,
    Color(0xFFFF8F6B),
    Color(0xFFFFC79E),
    Color(0xFF6FD6C1),
  ];

  @override
  void initState() {
    super.initState();
    _parts = List.generate(
      90,
      (_) => _Particle(
        x: _rng.nextDouble(),
        size: 6 + _rng.nextDouble() * 9,
        color: _colors[_rng.nextInt(_colors.length)],
        delay: _rng.nextDouble() * 0.35,
        drift: (_rng.nextDouble() - 0.5) * 0.4,
        rot: _rng.nextDouble() * 6.28,
        rotSpeed: (_rng.nextDouble() - 0.5) * 12,
      ),
    );
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_c.value, _parts),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.parts);
  final double t;
  final List<_Particle> parts;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in parts) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = -20 + local * (size.height + 40);
      final x = (p.x + p.drift * local) * size.width;
      final opacity = (1 - local * local).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(p.rot + p.rotSpeed * local);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
