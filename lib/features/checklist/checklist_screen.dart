import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/points_ledger_provider.dart';
import '../../state/providers.dart';
import '../../state/water_provider.dart';
import '../workouts/workout_library_screen.dart';
import 'activity_submission_screen.dart';
import 'step_task_screen.dart';
import 'widgets/task_tile.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _celebrate() {
    ref
        .read(pointsLedgerProvider.notifier)
        .add('Completed all daily tasks', AppConstants.dailyPointsTotal);
    _confetti.play();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _DayCompleteDialog(),
    );
  }

  /// Opens the correct submission flow for a task. The task is only marked
  /// complete once the flow returns success (a confirmed upload, or a verified
  /// step goal). Un-checking a completed task is allowed directly.
  Future<void> _handleToggle(DailyTaskType type, bool value, int day) async {
    if (!value) {
      ref.read(checklistProvider.notifier).setTask(type, false);
      return;
    }

    final bool success;
    if (type == DailyTaskType.dailySteps) {
      success = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => StepTaskScreen(challengeDay: day),
            ),
          ) ??
          false;
    } else if (type == DailyTaskType.fitnessActivity) {
      // The exercise task is completed by finishing a guided workout.
      success = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) =>
                  const WorkoutLibraryScreen(forTaskCompletion: true),
            ),
          ) ??
          false;
    } else {
      final outcome = await Navigator.of(context).push<Object?>(
        MaterialPageRoute(
          builder: (_) => ActivitySubmissionScreen(
            taskType: type,
            challengeDay: day,
          ),
        ),
      );
      success = outcome is SubmissionOutcome;
    }

    if (!success || !mounted) return;
    final bool wasAllDone = _daySixDone();
    ref.read(checklistProvider.notifier).setTask(type, true);
    if (!wasAllDone && _daySixDone()) _celebrate();
  }

  /// True when all five activity tasks AND the water goal (≥12 glasses) are
  /// complete — the full 6-task day.
  bool _daySixDone() {
    final c = ref.read(checklistProvider);
    final waterOk = ref.read(waterProvider) >= AppConstants.waterTaskGlasses;
    return c.allComplete && waterOk;
  }

  /// Adjusts water and celebrates if this is what completed the whole day.
  void _changeWater(int delta) {
    final bool wasAllDone = _daySixDone();
    final notifier = ref.read(waterMlProvider.notifier);
    delta > 0 ? notifier.addGlass() : notifier.removeGlass();
    if (!wasAllDone && _daySixDone()) _celebrate();
  }

  @override
  Widget build(BuildContext context) {
    final checklist = ref.watch(checklistProvider);
    final int glasses = ref.watch(waterProvider);
    final bool waterDone = glasses >= AppConstants.waterTaskGlasses;
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    // Water counts as one extra task worth its own points.
    final int totalTasks = checklist.tasks.length + 1;
    final int doneCount = checklist.completedCount + (waterDone ? 1 : 0);
    final double pct = totalTasks == 0 ? 0.0 : doneCount / totalTasks;
    final int points = checklist.pointsEarned +
        (waterDone ? AppConstants.waterTaskPoints : 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.challengeTodayTitle(checklist.day)),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, 100),
            children: [
              // Progress header
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l.tasksDone(doneCount, totalTasks),
                            style: text.titleMedium),
                        Text('${(pct * 100).round()}%',
                            style: text.titleMedium
                                ?.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        backgroundColor:
                            AppColors.primary.withOpacity(0.10),
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded,
                            size: 18, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                            l.pointsToday(
                                points, AppConstants.dailyPointsTotal),
                            style: text.bodyMedium),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(l.tapTaskHint, style: text.bodySmall),
              const SizedBox(height: AppSpacing.md),

              for (final task in checklist.tasks)
                TaskTile(
                  type: task.type,
                  completed: task.completed,
                  onToggle: (value) =>
                      _handleToggle(task.type, value, checklist.day),
                ),

              // Water intake — completed automatically at 12 glasses.
              _WaterTaskTile(
                onAdd: () => _changeWater(1),
                onRemove: () => _changeWater(-1),
              ),
            ],
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 24,
              maxBlastForce: 22,
              minBlastForce: 8,
              gravity: 0.25,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.accent,
                Color(0xFF7C5CFC),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The water task row: tap the card (or +) to add a glass, − to undo. Turns
/// green and is marked done once 12 glasses (3 L) are logged.
class _WaterTaskTile extends ConsumerWidget {
  const _WaterTaskTile({required this.onAdd, required this.onRemove});

  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int glasses = ref.watch(waterProvider);
    const int goal = AppConstants.waterTaskGlasses;
    final bool done = glasses >= goal;
    final String goalL = (goal * kGlassMl / 1000).toStringAsFixed(1);
    final TextTheme text = Theme.of(context).textTheme;
    final Color accentColor = done ? AppColors.success : AppColors.info;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        onTap: onAdd,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.water_drop_rounded, color: accentColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Water Intake', style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text('$glasses of $goal glasses · goal $goalL L',
                      style: text.bodySmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 3),
                      Text('+${AppConstants.waterTaskPoints} pts',
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.accent)),
                    ],
                  ),
                ],
              ),
            ),
            if (glasses > 0)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: AppColors.textSecondary,
                onPressed: onRemove,
              ),
            AnimatedScale(
              duration: const Duration(milliseconds: 250),
              scale: done ? 1.0 : 0.92,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.success : AppColors.info,
                ),
                child: Icon(done ? Icons.check_rounded : Icons.add_rounded,
                    size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCompleteDialog extends StatelessWidget {
  const _DayCompleteDialog();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l.dayCompletedTitle,
                style: text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.dayCompletedBody,
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.actionAwesome),
            ),
          ],
        ),
      ),
    );
  }
}
