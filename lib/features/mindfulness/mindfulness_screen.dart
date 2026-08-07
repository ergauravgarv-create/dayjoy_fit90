import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/mindfulness_provider.dart';
import 'breathing_data.dart';
import 'breathing_timer_screen.dart';

/// Calming music track (from the video library) used by the mindfulness screen.
const String kMeditationMusicVideo = 'https://youtu.be/YRJ6xoiRcpQ';

class MindfulnessScreen extends ConsumerWidget {
  const MindfulnessScreen({super.key});

  Future<void> _startBreathing(
      BuildContext context, WidgetRef ref, BreathPattern p) async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BreathingTimerScreen(pattern: p)),
    );
    if (done == true && context.mounted) {
      _logMindful(context, ref);
    }
  }

  void _logMindful(BuildContext context, WidgetRef ref) {
    final wasDone = ref.read(mindfulnessProvider.notifier).doneToday;
    ref.read(mindfulnessProvider.notifier).markDoneToday();
    if (!wasDone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧘 Mindful minute logged for today'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _openMusic(BuildContext context) async {
    final ok = await launchUrl(Uri.parse(kMeditationMusicVideo),
        mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the video.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    // Watch so the streak/done state stays fresh.
    ref.watch(mindfulnessProvider);
    final int streak = ref.read(mindfulnessProvider.notifier).streak;
    final bool doneToday = ref.read(mindfulnessProvider.notifier).doneToday;
    final int total = ref.read(mindfulnessProvider.notifier).totalSessions;

    return Scaffold(
      appBar: AppBar(title: const Text('Mindfulness')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: [
          // Streak header
          GlassCard(
            gradient: AppColors.mixGradient,
            child: Row(
              children: [
                const Icon(Icons.self_improvement_rounded,
                    color: Colors.white, size: 40),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$streak-day mindful streak',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      Text(
                          doneToday
                              ? 'Done today · $total sessions total'
                              : 'Take a mindful minute today',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.9))),
                    ],
                  ),
                ),
                if (doneToday)
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 26),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Breathing exercises
          Text('Breathing exercises', style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Follow the circle — it grows as you breathe in, shrinks as you '
              'breathe out.',
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          for (final p in kBreathPatterns)
            _PatternCard(
              pattern: p,
              text: text,
              onTap: () => _startBreathing(context, ref, p),
            ),
          const SizedBox(height: AppSpacing.xl),

          // Calm music
          Text('Calm music', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.info.withOpacity(0.14),
                      child: const Icon(Icons.music_note_rounded,
                          color: AppColors.info),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('30-min deep meditation music',
                              style: text.titleSmall),
                          Text('Relax mind & body · inner peace',
                              style: text.bodySmall?.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openMusic(context),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play on YouTube'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _logMindful(context, ref),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Mark done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  const _PatternCard(
      {required this.pattern, required this.text, required this.onTap});
  final BreathPattern pattern;
  final TextTheme text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mins = (pattern.totalSeconds / 60).ceil();
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
                color: pattern.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.air_rounded, color: pattern.color, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pattern.name, style: text.titleSmall),
                  Text(pattern.description,
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                  Text('${pattern.cycles} cycles · ~$mins min',
                      style: text.bodySmall
                          ?.copyWith(color: pattern.color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.play_circle_outline_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
