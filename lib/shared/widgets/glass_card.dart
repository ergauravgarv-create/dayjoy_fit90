import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Soft, rounded card with an optional frosted-glass effect and gentle shadow —
/// the workhorse surface across the app.
class GlassCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color base = isDark ? AppColors.surfaceDark : AppColors.surface;

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? base : null,
        gradient: gradient,
        borderRadius: AppRadius.card,
        border: frosted
            ? Border.all(color: Colors.white.withOpacity(0.25))
            : null,
        boxShadow: [
          BoxShadow(
            color: gradient != null
                ? AppColors.primary.withOpacity(0.25)
                : AppColors.shadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    if (frosted) {
      content = ClipRRect(
        borderRadius: AppRadius.card,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      return InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}
