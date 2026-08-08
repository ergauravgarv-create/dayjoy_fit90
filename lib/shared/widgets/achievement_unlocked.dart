import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Shows a celebratory "Achievement unlocked!" dialog with confetti, a badge
/// that springs in, and the badge title(s). Reusable from anywhere a badge is
/// earned (checklist, home, gallery) so the reward always feels special.
///
/// [titles] are the freshly-unlocked badge names. [icon] is shown on the medal.
Future<void> showAchievementUnlocked(
  BuildContext context, {
  required List<String> titles,
  IconData icon = Icons.emoji_events_rounded,
}) {
  if (titles.isEmpty) return Future<void>.value();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Achievement unlocked',
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) =>
        _AchievementDialog(titles: titles, icon: icon),
    transitionBuilder: (_, anim, __, child) => FadeTransition(
      opacity: anim,
      child: child,
    ),
  );
}

class _AchievementDialog extends StatefulWidget {
  const _AchievementDialog({required this.titles, required this.icon});
  final List<String> titles;
  final IconData icon;

  @override
  State<_AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<_AchievementDialog>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2))..play();
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _confetti.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String heading =
        widget.titles.length == 1 ? 'Achievement unlocked!' : 'Badges unlocked!';
    final String body = widget.titles.length <= 3
        ? widget.titles.join('  •  ')
        : '${widget.titles.take(2).join('  •  ')}  +${widget.titles.length - 2} more';

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Confetti bursts downward from the top-center.
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirection: math.pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 18,
            maxBlastForce: 22,
            minBlastForce: 8,
            gravity: 0.25,
            colors: const [
              AppColors.primary,
              AppColors.orange,
              AppColors.accent,
              Colors.white,
            ],
          ),
        ),
        Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _pop, curve: Curves.easeOutBack),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl,
                  AppSpacing.xl, AppSpacing.xl),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Spinning-in medal.
                  RotationTransition(
                    turns: Tween<double>(begin: -0.06, end: 0).animate(
                        CurvedAnimation(
                            parent: _pop, curve: Curves.easeOutBack)),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        gradient: AppColors.goldGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 52),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(heading,
                      textAlign: TextAlign.center,
                      style: text.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(body,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Awesome!'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
