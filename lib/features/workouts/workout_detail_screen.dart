import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import 'workout_data.dart';
import 'workout_player_screen.dart';

Future<void> _openUrl(BuildContext context, String url) async {
  final ok =
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the video.')),
    );
  }
}

/// Overview of a routine with its move list and a Start button. Pops `true` up
/// to the caller once the player reports the routine was finished.
class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, required this.workout});
  final Workout workout;

  Future<void> _start(BuildContext context) async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WorkoutPlayerScreen(workout: workout)),
    );
    if (done == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color color = workout.category.color;

    return Scaffold(
      appBar: AppBar(title: Text(workout.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
        children: [
          GlassCard(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(workout.category.icon, color: Colors.white, size: 30),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${workout.category.label} · ${workout.level.label}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(workout.focus,
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _pill(Icons.timer_outlined, '~${workout.estMinutes} min'),
                    const SizedBox(width: AppSpacing.sm),
                    _pill(Icons.list_rounded,
                        '${workout.exerciseCount} moves'),
                  ],
                ),
              ],
            ),
          ),
          if (workout.referenceVideoUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _openUrl(context, workout.referenceVideoUrl!),
                icon: const Icon(Icons.smart_display_rounded,
                    color: Color(0xFFFF0000)),
                label: const Text('Watch full follow-along video'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('The moves', style: text.titleMedium),
          const SizedBox(height: 2),
          Text('Tap the ▶ on any move for a how-to video.',
              style: text.bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < workout.exercises.length; i++)
            _MoveRow(
              index: i + 1,
              exercise: workout.exercises[i],
              color: color,
              onWatch: () => _openUrl(context, workout.exercises[i].youtubeUrl),
            ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _start(context),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start workout'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Finishing the routine completes your Fitness Activity task.',
              style: text.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.20),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _MoveRow extends StatelessWidget {
  const _MoveRow(
      {required this.index,
      required this.exercise,
      required this.color,
      required this.onWatch});
  final int index;
  final Exercise exercise;
  final Color color;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String amount =
        exercise.isTimed ? '${exercise.seconds}s' : '×${exercise.reps}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(0.14),
              child: Text('$index',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name, style: text.titleSmall),
                  Text(exercise.cue,
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(amount,
                style: text.titleMedium?.copyWith(
                    color: color, fontWeight: FontWeight.w800)),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Watch on YouTube',
              icon: const Icon(Icons.play_circle_outline_rounded,
                  color: Color(0xFFFF0000)),
              onPressed: onWatch,
            ),
          ],
        ),
      ),
    );
  }
}
