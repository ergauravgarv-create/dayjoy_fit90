import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import 'workout_videos.dart';

/// A browsable library of free YouTube follow-along videos, grouped by focus.
/// Separate from the timer-based cardio circuits. Tapping a card opens YouTube.
class VideoLibraryScreen extends StatelessWidget {
  const VideoLibraryScreen({super.key});

  static Color _catColor(String category) => switch (category) {
        'Warm-up' => AppColors.taskYoga,
        'Cardio' => AppColors.taskSteps,
        'Full body' => AppColors.orange,
        'Core' => AppColors.primary,
        'Legs' => AppColors.secondary,
        'Meditation & Relax' => AppColors.info,
        _ => AppColors.textSecondary,
      };

  static IconData _catIcon(String category) => switch (category) {
        'Warm-up' => Icons.self_improvement_rounded,
        'Cardio' => Icons.directions_run_rounded,
        'Full body' => Icons.accessibility_new_rounded,
        'Core' => Icons.fitness_center_rounded,
        'Legs' => Icons.airline_seat_legroom_extra_rounded,
        'Meditation & Relax' => Icons.spa_rounded,
        _ => Icons.play_circle_rounded,
      };

  Future<void> _open(BuildContext context, String url) async {
    final ok =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the video.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Videos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: [
          Text(
            'Free follow-along videos on YouTube. Tap any card to watch — '
            'separate from your timed cardio circuits.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final cat in kVideoCategories) ...[
            () {
              final items = videosInCategory(cat);
              if (items.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_catIcon(cat), size: 20, color: _catColor(cat)),
                      const SizedBox(width: AppSpacing.sm),
                      Text(cat, style: text.titleMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final v in items)
                    _VideoCard(
                      video: v,
                      color: _catColor(cat),
                      onTap: () => _open(context, v.url),
                      text: text,
                    ),
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

class _VideoCard extends StatelessWidget {
  const _VideoCard(
      {required this.video,
      required this.color,
      required this.onTap,
      required this.text});
  final WorkoutVideo video;
  final Color color;
  final VoidCallback onTap;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with a play overlay.
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (video.thumbnailUrl != null)
                      Image.network(
                        video.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbFallback(),
                        loadingBuilder: (ctx, child, progress) =>
                            progress == null ? child : _thumbFallback(),
                      )
                    else
                      _thumbFallback(),
                    Container(color: Colors.black.withOpacity(0.18)),
                    const Center(
                      child: Icon(Icons.play_circle_fill_rounded,
                          color: Colors.white, size: 54),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(video.title,
                            style: text.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        if (video.note != null) ...[
                          const SizedBox(height: 2),
                          Text(video.note!,
                              style: text.bodySmall?.copyWith(
                                  color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.smart_display_rounded,
                      color: Color(0xFFFF0000)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        color: color.withOpacity(0.16),
        alignment: Alignment.center,
        child: Icon(Icons.ondemand_video_rounded, color: color, size: 40),
      );
}
