import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

/// Горизонтальный таймлайн: недели беременности ИЛИ месяцы ребёнка.
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
      viewportFraction: 0.30,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
      height: 132,
      child: PageView.builder(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        onPageChanged: _handlePageChanged,
        itemCount: widget.totalSteps,
        itemBuilder: (context, index) {
          final bool isActive = index == _selected;
          return AnimatedScale(
            scale: isActive ? 1.0 : 0.80,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: isActive ? AppGradients.hero : null,
                color: isActive ? null : Colors.white,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.lavender.withValues(alpha: 0.35),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${index + 1}',
                      style: TextStyle(
                        fontSize: isActive ? 38 : 28,
                        fontWeight: FontWeight.w800,
                        color: isActive ? Colors.white : Colors.black26,
                      )),
                  Text(widget.unitLabel,
                      style: TextStyle(
                        fontSize: 12,
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
