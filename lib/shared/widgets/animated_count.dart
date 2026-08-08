import 'package:flutter/material.dart';

/// A number that counts up smoothly to [value] (and re-animates when it
/// changes) — a small touch that makes stats feel alive and premium.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 900),
    this.thousands = false,
  });

  final num value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimals;
  final Duration duration;
  final bool thousands;

  String _fmt(double v) {
    String s = v.toStringAsFixed(decimals);
    if (thousands) {
      final parts = s.split('.');
      final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );
      s = parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
    }
    return '$prefix$s$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(_fmt(v), style: style),
    );
  }
}
