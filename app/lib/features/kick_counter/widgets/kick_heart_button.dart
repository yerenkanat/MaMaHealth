import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Пульсирующее сердце-кнопка трекера шевелений плода.
class KickHeartButton extends StatefulWidget {
  const KickHeartButton({super.key, required this.onKick, required this.count});

  final VoidCallback onKick;
  final int count;

  @override
  State<KickHeartButton> createState() => _KickHeartButtonState();
}

class _KickHeartButtonState extends State<KickHeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseScale;
  double _tapScale = 1.0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseScale = Tween(begin: 0.96, end: 1.06)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose(); // никаких утечек AnimationController.
    super.dispose();
  }

  Future<void> _onTap() async {
    HapticFeedback.mediumImpact();
    widget.onKick();
    setState(() => _tapScale = 1.18);
    await Future.delayed(const Duration(milliseconds: 140));
    if (mounted) setState(() => _tapScale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _pulseScale,
        child: AnimatedScale(
          scale: _tapScale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFF8FB1), Color(0xFFF25C86)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF25C86).withOpacity(0.45),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 64),
                Text('${widget.count}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold)),
                const Text('шевелений',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
