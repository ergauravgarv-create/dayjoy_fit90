import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/achievements_provider.dart';

class BadgesGalleryScreen extends ConsumerStatefulWidget {
  const BadgesGalleryScreen({super.key});

  @override
  ConsumerState<BadgesGalleryScreen> createState() =>
      _BadgesGalleryScreenState();
}

class _BadgesGalleryScreenState extends ConsumerState<BadgesGalleryScreen> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    // Persist anything that has just crossed the finish line, and celebrate
    // whatever is newly unlocked this visit.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reconcile());
  }

  void _reconcile() {
    final views = ref.read(achievementsProvider);
    final completeNow =
        views.where((v) => v.progress >= 1.0).map((v) => v.def.id);
    final added = ref.read(earnedBadgesProvider.notifier).award(completeNow);
    if (added.isNotEmpty && mounted) {
      _confetti.play();
      final String msg;
      if (added.length <= 3) {
        final titles = kAchievements
            .where((d) => added.contains(d.id))
            .map((d) => d.title)
            .join(', ');
        msg = '🎉 Badge unlocked: $titles';
      } else {
        msg = '🎉 ${added.length} badges unlocked!';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final views = ref.watch(achievementsProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final stats = ref.watch(achievementStatsProvider);

    final int earnedCount = views.where((v) => v.earned).length;

    // "Next up" = the locked badge closest to completion.
    final locked = views.where((v) => !v.earned).toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final AchievementView? nextUp = locked.isEmpty ? null : locked.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
            children: [
              const SizedBox(height: AppSpacing.md),
              // Summary header
              GlassCard(
                gradient: AppColors.goldGradient,
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: Colors.white, size: 40),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$earnedCount / ${views.length} unlocked',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          Text('Keep going — every task earns a badge.',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Next up
              if (nextUp != null) ...[
                Text('Next up', style: text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                _NextUpCard(view: nextUp, stats: stats, text: text),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Sections by category
              for (final cat in AchievementCategory.values) ...[
                _SectionHeader(
                  category: cat,
                  views: views.where((v) => v.def.category == cat).toList(),
                  text: text,
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.86,
                  children: [
                    for (final v
                        in views.where((v) => v.def.category == cat))
                      _BadgeCard(view: v, stats: stats, text: text),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ],
          ),

          // Celebration overlay
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
                Color(0xFFFFC107),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.category, required this.views, required this.text});
  final AchievementCategory category;
  final List<AchievementView> views;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final color = achievementColor(category);
    final earned = views.where((v) => v.earned).length;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(category.label, style: text.titleMedium),
        const Spacer(),
        Text('$earned / ${views.length}',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _NextUpCard extends StatelessWidget {
  const _NextUpCard(
      {required this.view, required this.stats, required this.text});
  final AchievementView view;
  final AchievementStats stats;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final color = achievementColor(view.def.category);
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.14),
            ),
            child: Icon(view.def.icon, color: color, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(view.def.title, style: text.titleSmall),
                const SizedBox(height: 2),
                Text(view.def.status(stats),
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: view.progress,
                    minHeight: 8,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('${(view.progress * 100).round()}%',
              style: text.titleMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard(
      {required this.view, required this.stats, required this.text});
  final AchievementView view;
  final AchievementStats stats;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final bool earned = view.earned;
    final color = achievementColor(view.def.category);
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: earned ? AppColors.goldGradient : null,
              color: earned ? null : AppColors.surfaceMuted,
            ),
            child: Icon(
              earned ? view.def.icon : Icons.lock_rounded,
              color: earned ? Colors.white : AppColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(view.def.title,
              style: text.titleSmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(view.def.description,
              style: text.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.sm),
          if (earned)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 4),
                Text('Unlocked',
                    style: text.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700)),
              ],
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: view.progress,
                minHeight: 6,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(view.def.status(stats),
                style: text.bodySmall
                    ?.copyWith(color: AppColors.textSecondary, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}
