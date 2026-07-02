import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Универсальный таймлайн: недели беременности ИЛИ месяцы ребёнка.
class JourneyTimeline extends StatefulWidget {
  const JourneyTimeline({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.unitLabel,
    required this.onStepChanged,
  });

  final int totalSteps;
  final int currentStep;
  final String unitLabel;
  final ValueChanged<int> onStepChanged;

  @override
  State<JourneyTimeline> createState() => _JourneyTimelineState();
}

class _JourneyTimelineState extends State<JourneyTimeline> {
  late final PageController _controller;
  late int _selected = widget.currentStep;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: widget.currentStep,
      viewportFraction: 0.32,
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Code Reviewer: обязательное закрытие контроллера.
    super.dispose();
  }

  void _handlePageChanged(int page) {
    HapticFeedback.lightImpact();
    setState(() => _selected = page);
    widget.onStepChanged(page);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: PageView.builder(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        onPageChanged: _handlePageChanged,
        itemCount: widget.totalSteps,
        itemBuilder: (context, index) {
          final bool isActive = index == _selected;
          return AnimatedScale(
            scale: isActive ? 1.0 : 0.82,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: isActive
                      ? [const Color(0xFFF7B6C8), const Color(0xFFF3D2E1)]
                      : [const Color(0xFFF1F1F4), const Color(0xFFECECEF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFFF7B6C8).withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        )
                      ]
                    : const [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${index + 1}',
                      style: TextStyle(
                        fontSize: isActive ? 34 : 26,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : Colors.black38,
                      )),
                  Text(widget.unitLabel,
                      style: TextStyle(
                        color: isActive ? Colors.white70 : Colors.black26,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
