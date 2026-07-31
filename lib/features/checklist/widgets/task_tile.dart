import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/task_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass_card.dart';

/// A single daily-task row with an icon, title, points, and a completion
/// checkbox that turns the tile green when done.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.type,
    required this.completed,
    required this.onToggle,
  });

  final DailyTaskType type;
  final bool completed;
  final ValueChanged<bool> onToggle;

  IconData get _icon => switch (type) {
        DailyTaskType.morningYoga => Icons.self_improvement_rounded,
        DailyTaskType.morningNutrition => Icons.free_breakfast_rounded,
        DailyTaskType.fitnessActivity => Icons.fitness_center_rounded,
        DailyTaskType.dailySteps => Icons.directions_walk_rounded,
        DailyTaskType.nightNutrition => Icons.nightlight_round,
      };

  Color get _color => switch (type) {
        DailyTaskType.morningYoga => AppColors.taskYoga,
        DailyTaskType.morningNutrition => AppColors.taskMorningNutrition,
        DailyTaskType.fitnessActivity => AppColors.taskFitness,
        DailyTaskType.dailySteps => AppColors.taskSteps,
        DailyTaskType.nightNutrition => AppColors.taskNightNutrition,
      };

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        onTap: () => onToggle(!completed),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (completed ? AppColors.success : _color)
                    .withOpacity(0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(_icon,
                  color: completed ? AppColors.success : _color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(localizedTaskTitle(l, type), style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text(localizedTaskSubtitle(l, type), style: text.bodySmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 3),
                      Text(l.plusPoints(AppConstants.pointsPerTask),
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.accent)),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedScale(
              duration: const Duration(milliseconds: 250),
              scale: completed ? 1.0 : 0.9,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed ? AppColors.success : Colors.transparent,
                  border: Border.all(
                    color: completed
                        ? AppColors.success
                        : AppColors.textSecondary.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: completed
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
