import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Стилизованный «виртуальный плод» с мягкой анимацией дыхания и покачивания.
/// В проде здесь будет реальная Lottie/3D-модель по неделям.
class VirtualFetus extends StatefulWidget {
  const VirtualFetus({super.key, required this.week});

  final int week;

  @override
  State<VirtualFetus> createState() => _VirtualFetusState();
}

class _VirtualFetusState extends State<VirtualFetus>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) =>
            CustomPaint(painter: _FetusPainter(_c.value * 2 * math.pi)),
      ),
    );
  }
}

class _FetusPainter extends CustomPainter {
  _FetusPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    final breathe = 1 + 0.03 * math.sin(t);

    // Амниотический пузырь: мягкое свечение.
    final sac = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x338B7BF0), Color(0x1439C6A8), Color(0x0039C6A8)],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r * 0.95 * breathe, sac);
    canvas.drawCircle(
      c,
      r * 0.72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x2A8B7BF0),
    );

    // Плод: плавное покачивание + лёгкий наклон.
    final bob = 6 * math.sin(t);
    canvas.save();
    canvas.translate(c.dx, c.dy + bob);
    canvas.rotate(0.08 * math.sin(t * 0.7));

    final skin = Paint()..color = const Color(0xFFF4C7A8);
    final shade = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x22000000);

    final bw = r * 0.52;
    final bh = r * 0.64;

    // Тельце (свернувшийся «бобик»).
    final body = Rect.fromCenter(
        center: Offset(bw * 0.08, bh * 0.18), width: bw, height: bh);
    canvas.drawOval(body, skin);
    canvas.drawOval(body, shade);

    // Головка.
    final head = Offset(-bw * 0.18, -bh * 0.42);
    canvas.drawCircle(head, r * 0.27, skin);
    canvas.drawCircle(head, r * 0.27, shade);

    // Ножка-намёк.
    final leg = Path()
      ..moveTo(bw * 0.25, bh * 0.35)
      ..quadraticBezierTo(bw * 0.55, bh * 0.30, bw * 0.5, bh * 0.05);
    canvas.drawPath(
      leg,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.18
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF4C7A8),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FetusPainter old) => old.t != t;
}
