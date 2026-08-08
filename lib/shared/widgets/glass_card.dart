import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Soft, rounded card with an optional frosted-glass effect and gentle shadow —
/// the workhorse surface across the app. Tappable cards gently scale on press
/// for a premium, responsive feel.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.frosted = false,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool frosted;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color base = isDark ? AppColors.surfaceDark : AppColors.surface;

    Widget content = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.gradient == null ? base : null,
        gradient: widget.gradient,
        borderRadius: AppRadius.card,
        border: widget.frosted
            ? Border.all(color: Colors.white.withOpacity(0.25))
            : null,
        boxShadow: [
          BoxShadow(
            color: widget.gradient != null
                ? AppColors.primary.withOpacity(0.25)
                : AppColors.shadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.frosted) {
      content = ClipRRect(
        borderRadius: AppRadius.card,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: content,
        ),
      );
    }

    if (widget.onTap != null) {
      return AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: widget.onTap,
          onHighlightChanged: (v) {
            if (mounted) setState(() => _pressed = v);
          },
          child: content,
        ),
      );
    }
    return content;
  }
}
