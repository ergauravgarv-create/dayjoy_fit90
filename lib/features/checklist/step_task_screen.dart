import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/health_providers.dart';
import '../health/connect_health_screen.dart';
import 'activity_submission_screen.dart';

/// Whether manual step entry is enabled (admin-configurable; off by default).
final manualEntryAllowedProvider = Provider<bool>((ref) => false);

/// The 10,000-step task with three modes:
///  A) Automatic health sync  B) Screenshot verification  C) Manual entry.
class StepTaskScreen extends ConsumerStatefulWidget {
  const StepTaskScreen({super.key, required this.challengeDay});
  final int challengeDay;

  @override
  ConsumerState<StepTaskScreen> createState() => _StepTaskScreenState();
}

class _StepTaskScreenState extends ConsumerState<StepTaskScreen> {
  int _mode = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthConnectionControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool manualAllowed = ref.watch(manualEntryAllowedProvider);
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.stepTaskTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        children: [
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(
                  value: 0,
                  label: Text(l.modeAuto),
                  icon: const Icon(Icons.sync_rounded)),
              ButtonSegment(
                  value: 1,
                  label: Text(l.modeScreenshot),
                  icon: const Icon(Icons.image_rounded)),
              ButtonSegment(
                  value: 2,
                  label: Text(l.modeManual),
                  icon: const Icon(Icons.edit_rounded)),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_mode == 0) _AutoMode(challengeDay: widget.challengeDay),
          if (_mode == 1) _ScreenshotMode(challengeDay: widget.challengeDay),
          if (_mode == 2) _ManualMode(allowed: manualAllowed),
        ],
      ),
    );
  }
}

class _AutoMode extends ConsumerWidget {
  const _AutoMode({required this.challengeDay});
  final int challengeDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(healthConnectionControllerProvider);
    final controller =
        ref.read(healthConnectionControllerProvider.notifier);
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    if (!state.connected) {
      return GlassCard(
        child: Column(
          children: [
            const Icon(Icons.favorite_rounded,
                size: 44, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(l.connectHealthPromptTitle, style: text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.connectHealthPromptBody,
              style: text.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const ConnectHealthScreen()),
              ),
              child: Text(l.connectHealthData),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        GlassCard(
          child: Column(
            children: [
              Text('${state.todaySteps}',
                  style: text.displaySmall
                      ?.copyWith(color: AppColors.primary)),
              Text(l.ofStepsGoal(AppConstants.dailyStepGoal),
                  style: text.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: state.stepProgress,
                  minHeight: 12,
                  backgroundColor: AppColors.primary.withOpacity(0.10),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.lastSyncAt != null)
                Text(
                    l.lastSyncedAt(
                        DateFormat('h:mm a').format(state.lastSyncAt!),
                        state.integrationType.name),
                    style: text.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.syncNow,
                icon: const Icon(Icons.sync_rounded),
                label: Text(l.actionSyncNow),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                onPressed: state.goalReached
                    ? () => Navigator.of(context).pop(true)
                    : null,
                child: Text(
                    state.goalReached ? '${l.actionComplete} ✓' : l.notYet),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Demo helper — simulate crossing 10k without walking 10k steps.
        TextButton.icon(
          onPressed: () => controller.simulateReachGoal(),
          icon: const Icon(Icons.bolt_rounded, size: 18),
          label: Text(l.demoSimulateSteps),
        ),
      ],
    );
  }
}

class _ScreenshotMode extends ConsumerWidget {
  const _ScreenshotMode({required this.challengeDay});
  final int challengeDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    return GlassCard(
      child: Column(
        children: [
          const Icon(Icons.image_search_rounded,
              size: 44, color: AppColors.taskSteps),
          const SizedBox(height: AppSpacing.md),
          Text(l.uploadScreenshotTitle, style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.uploadScreenshotBody,
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () async {
              final outcome = await Navigator.of(context).push<Object?>(
                MaterialPageRoute(
                  builder: (_) => ActivitySubmissionScreen(
                    taskType: DailyTaskType.dailySteps,
                    challengeDay: challengeDay,
                  ),
                ),
              );
              if (outcome is SubmissionOutcome && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.screenshotSubmitted)));
                Navigator.of(context).pop(true);
              }
            },
            icon: const Icon(Icons.upload_rounded),
            label: Text(l.uploadScreenshot),
          ),
        ],
      ),
    );
  }
}

class _ManualMode extends ConsumerStatefulWidget {
  const _ManualMode({required this.allowed});
  final bool allowed;

  @override
  ConsumerState<_ManualMode> createState() => _ManualModeState();
}

class _ManualModeState extends ConsumerState<_ManualMode> {
  final TextEditingController _steps = TextEditingController();
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _steps.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    if (!widget.allowed) {
      return GlassCard(
        child: Column(
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 44, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(l.manualDisabledTitle, style: text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.manualDisabledBody,
              style: text.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.manualTitle, style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(l.manualBody, style: text.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _steps,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.fieldStepCount),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _reason,
            decoration: InputDecoration(labelText: l.fieldReason),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.submitForReview),
          ),
        ],
      ),
    );
  }
}
