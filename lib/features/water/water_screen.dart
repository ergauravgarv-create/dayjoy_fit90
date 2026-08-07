import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/bar_series_chart.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../state/water_provider.dart';

class WaterScreen extends ConsumerWidget {
  const WaterScreen({super.key});

  static const LinearGradient _blue = LinearGradient(
    colors: [AppColors.info, AppColors.taskSteps],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  String _fmt(int ml) =>
      ml >= 1000 ? '${(ml / 1000).toStringAsFixed(2)} L' : '$ml ml';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int ml = ref.watch(waterMlProvider);
    final int goal = ref.watch(waterGoalMlProvider);
    final List<int> weekMl = ref.watch(weeklyWaterMlProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final double pct = (ml / goal).clamp(0.0, 1.0).toDouble();

    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    const wd = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final labels = [
      for (int i = 6; i >= 0; i--) wd[base.subtract(Duration(days: i)).weekday]
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Water')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
        children: [
          // Ring + today total
          GlassCard(
            child: Column(
              children: [
                ProgressRing(
                  progress: pct,
                  size: 150,
                  strokeWidth: 14,
                  gradient: _blue,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_fmt(ml),
                          style: text.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text('of ${_fmt(goal)}',
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  ml >= goal
                      ? '🎉 Goal reached — great hydration!'
                      : '${_fmt(goal - ml)} to your goal',
                  style: text.bodyMedium?.copyWith(
                      color: ml >= goal
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick add
          Text('Quick add', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final cup in kCupSizes)
                FilledButton.tonalIcon(
                  onPressed: () =>
                      ref.read(waterMlProvider.notifier).addMl(cup),
                  icon: const Icon(Icons.local_drink_rounded, size: 18),
                  label: Text('+$cup ml'),
                ),
              OutlinedButton.icon(
                onPressed: ml > 0
                    ? () =>
                        ref.read(waterMlProvider.notifier).removeMl(kGlassMl)
                    : null,
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('Undo'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Custom goal
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Daily goal', style: text.titleMedium),
                    const Spacer(),
                    Text(_fmt(goal),
                        style: text.titleMedium
                            ?.copyWith(color: AppColors.info)),
                  ],
                ),
                Slider(
                  value: goal.toDouble(),
                  min: 1000,
                  max: 6000,
                  divisions: 20,
                  label: _fmt(goal),
                  onChanged: (v) =>
                      ref.read(waterGoalMlProvider.notifier).setGoal(v.toInt()),
                ),
                Text(
                    'Daily task still needs ${AppConstants.waterTaskGlasses} glasses '
                    '(${(AppConstants.waterTaskGlasses * kGlassMl / 1000).toStringAsFixed(1)} L) for its points.',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Weekly chart
          Text('This week', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: BarSeriesChart(
              values: [for (final m in weekMl) m / 1000.0],
              labels: labels,
              gradient: _blue,
            ),
          ),
        ],
      ),
    );
  }
}
