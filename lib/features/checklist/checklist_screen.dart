import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/providers.dart';
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
    final bool justFinished =
        ref.read(checklistProvider.notifier).setTask(type, true);
    if (justFinished) _celebrate();
  }

  @override
  Widget build(BuildContext context) {
    final checklist = ref.watch(checklistProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

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
                        Text(
                            l.tasksDone(checklist.completedCount,
                                checklist.tasks.length),
                            style: text.titleMedium),
                        Text('${(checklist.completionPercent * 100).round()}%',
                            style: text.titleMedium
                                ?.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: checklist.completionPercent,
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
                            l.pointsToday(checklist.pointsEarned,
                                AppConstants.dailyPointsTotal),
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
