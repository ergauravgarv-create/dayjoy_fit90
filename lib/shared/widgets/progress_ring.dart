import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Animated circular progress ring used for the challenge completion indicator.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 160,
    this.strokeWidth = 14,
    this.gradient = AppColors.brandGradient,
    this.center,
  });

  /// 0..1
  final double progress;
  final double size;
  final double strokeWidth;
  final Gradient gradient;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              strokeWidth: strokeWidth,
              gradient: gradient,
              trackColor: isDark
                  ? Colors.white.withOpacity(0.06)
                  : AppColors.primary.withOpacity(0.08),
            ),
            child: Center(child: center),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Gradient gradient;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.width - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint track = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final Paint arc = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double start = -math.pi / 2;
    canvas.drawArc(rect, start, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.gradient != gradient;
}
