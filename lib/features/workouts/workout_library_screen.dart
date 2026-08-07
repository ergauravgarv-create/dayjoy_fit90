import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/providers.dart';
import 'video_library_screen.dart';
import 'workout_data.dart';
import 'workout_detail_screen.dart';

/// Browse workouts by category & level. When [forTaskCompletion] is true the
/// screen was opened from the daily checklist, so finishing a routine pops
/// `true` back to it. Otherwise it credits the Fitness Activity task directly.
class WorkoutLibraryScreen extends ConsumerStatefulWidget {
  const WorkoutLibraryScreen({super.key, this.forTaskCompletion = false});
  final bool forTaskCompletion;

  @override
  ConsumerState<WorkoutLibraryScreen> createState() =>
      _WorkoutLibraryScreenState();
}

class _WorkoutLibraryScreenState extends ConsumerState<WorkoutLibraryScreen> {
  WorkoutLevel? _level; // null = all levels
  Intensity? _intensity; // null = use the recommended one
  int _minutes = 30; // 30 / 45 / 60

  Future<void> _openWorkout(Workout w) async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: w)),
    );
    if (done != true || !mounted) return;

    if (widget.forTaskCompletion) {
      Navigator.pop(context, true); // checklist marks the task + celebrates
    } else {
      ref
          .read(checklistProvider.notifier)
          .setTask(DailyTaskType.fitnessActivity, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💪 Fitness Activity task completed!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  bool _passesLevel(Workout w) => _level == null || w.level == _level;

  Future<void> _startMySession(Intensity intensity) async {
    final w = buildSession(intensity: intensity, minutes: _minutes);
    await _openWorkout(w);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final participant = ref.watch(participantProvider);

    final String bmiCategory = participant?.bmiCategory ?? 'Normal';
    final String? activity = participant?.physicalActivityLevel;
    final Intensity recommended = recommendedIntensity(
        bmiCategory: bmiCategory, activityLevel: activity);
    final Intensity intensity = _intensity ?? recommended;

    return Scaffold(
      appBar: AppBar(title: const Text('Workouts')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: [
          if (widget.forTaskCompletion)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                'Pick a routine and finish it to complete today\'s Fitness '
                'Activity task.',
                style:
                    text.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),

          // ---- Personalised session builder ----
          Text('Recommended for you', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: intensity.color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(intensity.icon, color: intensity.color),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${intensity.label} · ${intensity.blurb}',
                              style: text.titleSmall),
                          Text(
                              intensityReason(
                                  bmiCategory: bmiCategory,
                                  activityLevel: activity),
                              style: text.bodySmall?.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Intensity', style: text.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final it in Intensity.values)
                      ChoiceChip(
                        label: Text(it == recommended
                            ? '${it.label} ✓'
                            : it.label),
                        selected: intensity == it,
                        labelStyle: TextStyle(
                          color: intensity == it
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedColor: it.color,
                        onSelected: (_) => setState(() => _intensity = it),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Duration', style: text.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final m in const [30, 45, 60])
                      ChoiceChip(
                        label: Text('$m min'),
                        selected: _minutes == m,
                        labelStyle: TextStyle(
                          color: _minutes == m
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedColor: AppColors.primary,
                        onSelected: (_) => setState(() => _minutes = m),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _startMySession(intensity),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('Start my $_minutes-min session'),
                  ),
                ),
                const SizedBox(height: 4),
                Text('30s work / 30s rest · with beep + vibration cues',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Jump to the separate follow-along video library.
          GlassCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const VideoLibraryScreen()),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_display_rounded,
                    color: Color(0xFFFF0000)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text('Prefer to follow a video? Browse the video library',
                      style: text.bodyMedium),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Or browse routines', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          // Level filter
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _LevelChip(
                label: 'All levels',
                selected: _level == null,
                onTap: () => setState(() => _level = null),
              ),
              for (final lvl in WorkoutLevel.values)
                _LevelChip(
                  label: lvl.label,
                  selected: _level == lvl,
                  onTap: () => setState(() => _level = lvl),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final cat in WorkoutCategory.values) ...[
            () {
              final items = workoutsIn(cat).where(_passesLevel).toList();
              if (items.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(cat.icon, color: cat.color, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(cat.label, style: text.titleMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final w in items)
                    _WorkoutCard(
                        workout: w, onTap: () => _openWorkout(w), text: text),
                  const SizedBox(height: AppSpacing.xl),
                ],
              );
            }(),
          ],
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: AppColors.primary,
      onSelected: (_) => onTap(),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard(
      {required this.workout, required this.onTap, required this.text});
  final Workout workout;
  final VoidCallback onTap;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final color = workout.category.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(workout.category.icon, color: color, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workout.title, style: text.titleSmall),
                  const SizedBox(height: 2),
                  Text(workout.focus,
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                      '${workout.level.label} · ~${workout.estMinutes} min · '
                      '${workout.exerciseCount} moves',
                      style: text.bodySmall?.copyWith(
                          color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
