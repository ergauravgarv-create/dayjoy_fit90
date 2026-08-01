import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/weekly_report.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/bar_series_chart.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_tile.dart';
import '../../shared/widgets/weight_line_chart.dart';
import '../../data/models/participant.dart';
import '../../state/providers.dart';
import '../../state/report_providers.dart';
import '../../state/water_provider.dart';
import 'transformation_stories.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participant = ref.watch(participantProvider)!;
    final TextTheme text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    // Server-generated weekly reports (mock-seeded until Firebase is on).
    final List<WeeklyReport> reports =
        ref.watch(weeklyReportsProvider).valueOrNull ?? const [];
    final WeeklyReport? latest = reports.isNotEmpty ? reports.last : null;

    // Weight trend from the reports' weekly end-weights (fallback to the mock
    // series when no reports exist yet).
    final List<double> reportWeights = [
      for (final r in reports)
        if (r.endWeightKg != null) r.endWeightKg!,
    ];
    final List<double> series = reportWeights.length >= 2
        ? reportWeights
        : ref.watch(weightSeriesProvider);

    final NumberFormat n = NumberFormat.decimalPattern();

    return Scaffold(
      appBar: AppBar(title: Text(l.progressTitle)),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 100),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.45,
            children: [
              StatTile(
                icon: Icons.trending_down_rounded,
                value: '-${participant.weightLostKg.toStringAsFixed(1)} kg',
                label: l.statWeightLost,
                color: AppColors.success,
              ),
              StatTile(
                icon: Icons.monitor_heart_rounded,
                value: (latest?.bmi ?? participant.bmi).toStringAsFixed(1),
                label: l.statCurrentBmi,
                color: AppColors.primary,
              ),
              StatTile(
                icon: Icons.percent_rounded,
                value: '${(participant.goalProgress * 100).round()}%',
                label: l.statToTarget,
                color: AppColors.accent,
              ),
              StatTile(
                icon: Icons.timer_rounded,
                value: '${latest?.workoutMinutes ?? 0}',
                label: l.statWorkoutMins,
                color: AppColors.taskFitness,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: l.homeWeightTrend),
          const SizedBox(height: AppSpacing.md),
          GlassCard(child: WeightLineChart(values: series, height: 200)),
          const SizedBox(height: AppSpacing.xl),

          // Water — today + last 7 days
          const SectionHeader(title: 'Water intake'),
          const SizedBox(height: AppSpacing.md),
          const _WaterProgressCard(),
          const SizedBox(height: AppSpacing.xl),

          // Weekly completion — from the generated reports.
          if (reports.isNotEmpty) ...[
            SectionHeader(title: l.completionLast7),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: BarSeriesChart(
                values: [for (final r in reports) r.completionRate],
                labels: [for (final r in reports) l.weekShort(r.weekNumber)],
                asPercent: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          SectionHeader(title: l.transformationGallery),
          const SizedBox(height: AppSpacing.md),
          _BeforeAfterCard(participant: participant),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) => Container(
                width: 100,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_camera_back_rounded,
                        color: AppColors.textSecondary, size: 30),
                    const SizedBox(height: 6),
                    Text(l.weekShort(i + 1), style: text.bodySmall),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Community success stories (inspiration only — see disclaimer).
          const SectionHeader(title: 'Get inspired'),
          const SizedBox(height: AppSpacing.md),
          const TransformationStoriesCarousel(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pictures and stories are for inspiration only and may not reflect '
            'individual results.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: l.thisWeek),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            child: Column(
              children: [
                _WeeklyRow(
                    label: l.rowDaysCompleted,
                    value:
                        '${latest?.daysCompleted ?? 0} / ${latest?.daysInWeek ?? 7}'),
                _WeeklyRow(
                    label: l.rowTotalSteps,
                    value: n.format(latest?.totalSteps ?? 0)),
                _WeeklyRow(
                    label: l.rowActiveCalories,
                    value: '${n.format(latest?.activeCalories ?? 0)} kcal'),
                _WeeklyRow(
                    label: l.rowCompletionRate,
                    value:
                        '${((latest?.completionRate ?? 0) * 100).round()}%',
                    last: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BeforeAfterCard extends StatelessWidget {
  const _BeforeAfterCard({required this.participant});
  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final double lost = participant.weightLostKg;
    final int day = participant.currentDay;
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _photoCol(
                context, 'Before', 'Day 1', participant.startWeightKg, false),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_forward_rounded,
                    color: AppColors.textSecondary),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text('-${lost.toStringAsFixed(1)} kg',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 4),
                Text('$day days',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Expanded(
            child: _photoCol(context, 'Now', 'Day $day',
                participant.currentWeightKg, true),
          ),
        ],
      ),
    );
  }

  Widget _photoCol(BuildContext context, String tag, String sub, double kg,
      bool highlight) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: highlight
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.person_rounded,
                      size: 46, color: AppColors.textSecondary),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (highlight ? AppColors.primary : Colors.black)
                          .withOpacity(highlight ? 1 : 0.45),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(tag,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(sub, style: text.bodySmall),
        Text('${kg.toStringAsFixed(1)} kg',
            style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: highlight ? AppColors.primary : null)),
      ],
    );
  }
}

class _WaterProgressCard extends ConsumerWidget {
  const _WaterProgressCard();

  static const LinearGradient _blue = LinearGradient(
    colors: [AppColors.info, AppColors.taskSteps],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const List<String> _wd = [
    '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int today = ref.watch(waterProvider);
    final List<int> week = ref.watch(weeklyWaterProvider);
    const int goal = AppConstants.waterTaskGlasses;
    final double pct = (today / goal).clamp(0.0, 1.0);
    final int ml = today * kGlassMl;
    final String goalL = (goal * kGlassMl / 1000).toStringAsFixed(1);
    final TextTheme text = Theme.of(context).textTheme;

    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final labels = [
      for (int i = 6; i >= 0; i--)
        _wd[base.subtract(Duration(days: i)).weekday]
    ];

    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              ProgressRing(
                progress: pct,
                size: 64,
                strokeWidth: 7,
                gradient: _blue,
                center: Text('$today/$goal',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$today of $goal glasses today',
                        style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text('$ml ml · goal $goalL L', style: text.bodySmall),
                    if (today >= goal) ...[
                      const SizedBox(height: 2),
                      Text('Goal met · +${AppConstants.waterTaskPoints} pts',
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.success)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          BarSeriesChart(
            values: [for (final g in week) g.toDouble()],
            labels: labels,
            gradient: _blue,
          ),
        ],
      ),
    );
  }
}

class _WeeklyRow extends StatelessWidget {
  const _WeeklyRow(
      {required this.label, required this.value, this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: text.bodyMedium),
              Text(value, style: text.titleSmall),
            ],
          ),
        ),
        if (!last) const Divider(height: 1),
      ],
    );
  }
}
