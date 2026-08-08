import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A friendly, branded "nothing here yet" panel: a soft gradient icon badge, a
/// clear headline, a gentle explainer, and an optional call-to-action button.
///
/// Use it anywhere a list/section can be empty so the screen feels intentional
/// and inviting instead of blank. Example:
/// ```dart
/// EmptyState(
///   icon: Icons.restaurant_rounded,
///   title: 'No meals logged yet',
///   message: 'Add your first meal to start tracking today.',
///   actionLabel: 'Log a meal',
///   onAction: _openFoodSearch,
/// )
/// ```
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.gradient,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Accent gradient for the icon badge (defaults to the brand gradient).
  final Gradient? gradient;

  /// Tighter spacing for use inside a card/section rather than a full page.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color subtle =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final double badge = compact ? 64 : 88;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: compact ? AppSpacing.lg : AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: badge,
              height: badge,
              decoration: BoxDecoration(
                gradient: gradient ?? AppColors.brandGradient,
                borderRadius: BorderRadius.circular(badge / 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: badge * 0.5),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: subtle),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl, vertical: 0),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
