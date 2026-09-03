import 'dart:convert';

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
import '../../state/measurements_provider.dart';
import '../../state/progress_photos_provider.dart';
import '../../state/providers.dart';
import '../../state/report_providers.dart';
import '../../state/repository_providers.dart';
import '../../state/trend_analytics.dart';
import '../../state/water_provider.dart';
import 'progress_photos_screen.dart';
import 'share_card_screen.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participant = ref.watch(participantProvider)!;
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
    // Prefer the participant's own logged measurements when available.
    final measurements = ref.watch(measurementsProvider);
    final List<double> loggedWeights =
        measurements.map((m) => m.weightKg).toList();
    final List<double> loggedWaists =
        measurements.where((m) => m.waistCm != null).map((m) => m.waistCm!).toList();

    final List<double> series = loggedWeights.length >= 2
        ? loggedWeights
        : (reportWeights.length >= 2
            ? reportWeights
            : ref.watch(weightSeriesProvider));

    final NumberFormat n = NumberFormat.decimalPattern();

    final TrendAnalytics trends = computeTrends(
      startWeight: participant.startWeightKg,
      currentWeight: participant.currentWeightKg,
      targetWeight: participant.targetWeightKg,
      heightCm: participant.heightCm,
      startDate: participant.startDate,
      currentDay: participant.currentDay,
      logs: [for (final m in measurements) WeightLog(m.date, m.weightKg)],
      weightSeries: series,
      now: DateTime.now(),
    );
    final int streak = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.progressTitle),
        actions: [
          IconButton(
            tooltip: 'Share progress',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const ShareCardScreen()),
            ),
          ),
        ],
      ),
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

          const SectionHeader(title: 'Insights'),
          const SizedBox(height: AppSpacing.md),
          _InsightsCard(trends: trends, streak: streak, participant: participant),
          const SizedBox(height: AppSpacing.xl),

          Row(
            children: [
              Expanded(child: SectionHeader(title: l.homeWeightTrend)),
              TextButton.icon(
                onPressed: () => _logMeasurement(context, ref, participant),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Log'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GlassCard(child: WeightLineChart(values: series, height: 200)),
          const SizedBox(height: AppSpacing.xl),

          if (trends.bmiSeries.length >= 2) ...[
            const SectionHeader(title: 'BMI trend'),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
                child:
                    WeightLineChart(values: trends.bmiSeries, height: 160)),
            const SizedBox(height: AppSpacing.xl),
          ],

          if (loggedWaists.length >= 2) ...[
            const SectionHeader(title: 'Waist trend (cm)'),
            const SizedBox(height: AppSpacing.md),
            GlassCard(child: WeightLineChart(values: loggedWaists, height: 160)),
            const SizedBox(height: AppSpacing.xl),
          ],

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
          const _ProgressPhotosCard(),
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

class _InsightsCard extends StatelessWidget {
  const _InsightsCard(
      {required this.trends, required this.streak, required this.participant});
  final TrendAnalytics trends;
  final int streak;
  final Participant participant;

  ({String label, Color color}) get _pace => switch (trends.pace) {
        'ahead' => (label: 'Ahead of plan', color: AppColors.success),
        'onTrack' => (label: 'On track', color: AppColors.primary),
        'slow' => (label: 'Behind plan', color: AppColors.orange),
        _ => (label: 'Getting started', color: AppColors.textSecondary),
      };

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final pace = _pace;
    final double chg = trends.weeklyChangeKg;
    final bool losing = chg < 0;

    final String projection = trends.goalReached
        ? '🎉 Target reached!'
        : (trends.projectedGoalDate != null
            ? '${DateFormat('d MMM yyyy').format(trends.projectedGoalDate!)} · ~${trends.daysToGoal} days'
            : 'Keep logging to project a date');

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: pace.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(pace.label,
                    style: text.bodySmall?.copyWith(
                        color: pace.color, fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              Text('Target ${participant.targetWeightKg.toStringAsFixed(0)} kg',
                  style: text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InsightRow(
            icon: losing
                ? Icons.trending_down_rounded
                : Icons.trending_up_rounded,
            iconColor: losing ? AppColors.success : AppColors.error,
            label: 'This week',
            value: '${chg <= 0 ? '−' : '+'}${chg.abs().toStringAsFixed(1)} kg',
          ),
          _InsightRow(
            icon: Icons.speed_rounded,
            iconColor: AppColors.primary,
            label: 'Average pace',
            value: '${trends.weeklyRateKg.toStringAsFixed(1)} kg / week',
          ),
          _InsightRow(
            icon: Icons.flag_rounded,
            iconColor: AppColors.accent,
            label: 'Projected goal',
            value: projection,
          ),
          _InsightRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.orange,
            label: 'Current streak',
            value: '$streak days',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.last = false,
  });
  final IconData icon;
  final Color iconColor;
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
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: text.bodyMedium),
              const Spacer(),
              Flexible(
                child: Text(value,
                    style: text.titleSmall,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        if (!last) const Divider(height: 1),
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

Future<void> _logMeasurement(
    BuildContext context, WidgetRef ref, Participant participant) async {
  final weightCtrl = TextEditingController(
      text: participant.currentWeightKg.toStringAsFixed(1));
  final waistCtrl =
      TextEditingController(text: participant.waistCm?.toStringAsFixed(0) ?? '');

  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log measurement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Weight (kg)'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: waistCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Waist (cm, optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save')),
      ],
    ),
  );

  if (ok == true) {
    final w = double.tryParse(weightCtrl.text.trim());
    final waist = double.tryParse(waistCtrl.text.trim());
    if (w != null && w > 0) {
      ref.read(measurementsProvider.notifier).add(weightKg: w, waistCm: waist);
      await ref.read(participantRepositoryProvider).updateWeight(participant.id, w);
      ref.invalidate(participantProvider);
    }
  }
  weightCtrl.dispose();
  waistCtrl.dispose();
}

/// Home card linking to the progress-photos gallery, showing before/after.
class _ProgressPhotosCard extends ConsumerWidget {
  const _ProgressPhotosCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(progressPhotosProvider);
    final TextTheme text = Theme.of(context).textTheme;
    return GlassCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ProgressPhotosScreen()),
      ),
      child: photos.length >= 2
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Your photos', style: text.titleMedium),
                    const Spacer(),
                    Text('Manage',
                        style: text.bodySmall
                            ?.copyWith(color: AppColors.primary)),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _photo(photos.first.data, 'First')),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: AppColors.textSecondary),
                    ),
                    Expanded(
                        child: _photo(photos.last.data, 'Latest',
                            highlight: true)),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: const Icon(Icons.add_a_photo_rounded,
                      color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Progress photos', style: text.titleMedium),
                      Text('Add photos to build your before/after',
                          style: text.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
    );
  }

  Widget _photo(String data, String caption, {bool highlight = false}) {
    return Column(
      children: [
        SizedBox(
          height: 130,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.memory(base64Decode(data), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 4),
        Text(caption,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: highlight ? AppColors.primary : AppColors.textSecondary)),
      ],
    );
  }
}
