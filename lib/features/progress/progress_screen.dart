import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/weekly_report.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/bar_series_chart.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_tile.dart';
import '../../shared/widgets/weight_line_chart.dart';
import '../../state/providers.dart';
import '../../state/report_providers.dart';

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
