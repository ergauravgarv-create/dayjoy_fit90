import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/meal_photos_provider.dart';
import '../../state/meal_provider.dart';
import '../../state/providers.dart';
import 'food_diary_screen.dart';
import 'meal_data.dart';

const List<String> _weekdayShort = [
  '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
];

class WeeklyNutritionScreen extends ConsumerWidget {
  const WeeklyNutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(weeklyNutritionProvider);
    final participant = ref.watch(participantProvider);
    final int calorieGoal = participant?.dailyCalorieGoal ?? kCalorieGoal;
    final int proteinGoal = participant?.dailyProteinGoal ?? kProteinGoal;
    final TextTheme text = Theme.of(context).textTheme;

    final logged = days.where((d) => d.logged).toList();
    final int avgKcal = logged.isEmpty
        ? 0
        : (logged.fold(0, (s, d) => s + d.kcal) / logged.length).round();
    final int avgProtein = logged.isEmpty
        ? 0
        : (logged.fold(0.0, (s, d) => s + d.protein) / logged.length).round();

    return Scaffold(
      appBar: AppBar(title: const Text('This Week')),
      body: logged.isEmpty
          ? _EmptyWeek(text: text)
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
              children: [
                // Summary
                GlassCard(
                  gradient: AppColors.brandGradient,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Row(
                    children: [
                      _Summary(value: '$avgKcal', label: 'avg kcal/day'),
                      _divider(),
                      _Summary(value: '$avgProtein g', label: 'avg protein'),
                      _divider(),
                      _Summary(
                          value: '${logged.length}/7', label: 'days logged'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Calories chart
                _ChartCard(
                  title: 'Calories',
                  goalLabel: 'Goal $calorieGoal kcal/day',
                  chart: _WeekBars(
                    days: days,
                    value: (d) => d.kcal.toDouble(),
                    goal: calorieGoal.toDouble(),
                    higherIsBetter: false,
                    unit: 'kcal',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Protein chart
                _ChartCard(
                  title: 'Protein',
                  goalLabel: 'Goal $proteinGoal g/day',
                  chart: _WeekBars(
                    days: days,
                    value: (d) => d.protein,
                    goal: proteinGoal.toDouble(),
                    higherIsBetter: true,
                    unit: 'g',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Average macros
                _AvgMacros(logged: logged),
                const SizedBox(height: AppSpacing.xl),

                // Meal photos this week + link to the full diary
                const _MealPhotosSection(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Green bars hit your goal. Days without any logged meals show '
                  'as empty — log daily for the most accurate picture.',
                  style: text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 34, color: Colors.white24);
}

class _MealPhotosSection extends ConsumerWidget {
  const _MealPhotosSection();

  void _view(BuildContext context, String data) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.memory(base64Decode(data), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diary = ref.watch(foodDiaryProvider);
    final TextTheme text = Theme.of(context).textTheme;

    final entries = <({DateTime date, MealType type, String data})>[];
    for (final d in diary) {
      for (final e in d.photos.entries) {
        entries.add((date: d.date, type: e.key, data: e.value));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Meal photos', style: text.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const FoodDiaryScreen()),
              ),
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: const Text('Food diary'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (entries.isEmpty)
          Text(
            'Snap a photo of your plate in the Meal Tracker — your meal '
            'pictures show up here and in your food diary.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          )
        else
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final e = entries[i];
                return GestureDetector(
                  onTap: () => _view(context, e.data),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Image.memory(base64Decode(e.data),
                            width: 84, height: 84, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 3),
                      Text('${DateFormat('EEE').format(e.date)} · ${e.type.label}',
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard(
      {required this.title, required this.goalLabel, required this.chart});
  final String title;
  final String goalLabel;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: text.titleMedium),
              Text(goalLabel,
                  style: text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(height: 170, child: chart),
        ],
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({
    required this.days,
    required this.value,
    required this.goal,
    required this.higherIsBetter,
    required this.unit,
  });

  final List<DayNutrition> days;
  final double Function(DayNutrition) value;
  final double goal;
  final bool higherIsBetter;
  final String unit;

  Color _colorFor(double v) {
    if (v <= 0) return Colors.grey.withOpacity(0.25);
    if (higherIsBetter) {
      return v >= goal ? AppColors.success : AppColors.orange;
    }
    return v <= goal * 1.05 ? AppColors.success : AppColors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final double maxVal = days.fold<double>(
        0, (m, d) => value(d) > m ? value(d) : m);
    final double maxY = (maxVal > goal ? maxVal : goal) * 1.25 + 1;

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${rod.toY.round()} $unit',
              const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 3).clamp(1.0, 100000.0),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final int i = v.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_weekdayShort[days[i].date.weekday],
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: value(days[i]),
                  color: _colorFor(value(days[i])),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AvgMacros extends StatelessWidget {
  const _AvgMacros({required this.logged});
  final List<DayNutrition> logged;

  @override
  Widget build(BuildContext context) {
    final int n = logged.length;
    double avg(double Function(DayNutrition) sel) =>
        n == 0 ? 0 : logged.fold(0.0, (s, d) => s + sel(d)) / n;

    final TextTheme text = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Average per logged day', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _macro('Carbs', avg((d) => d.totals.carbs)),
              _macro('Fat', avg((d) => d.totals.fat)),
              _macro('Fibre', avg((d) => d.totals.fibre)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macro(String label, double grams) => Expanded(
        child: Column(
          children: [
            Text('${grams.round()} g',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _EmptyWeek extends StatelessWidget {
  const _EmptyWeek({required this.text});
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insights_rounded,
                size: 64, color: AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text('No meals logged this week', style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Log your breakfast, lunch and dinner for a few days and your '
              'weekly calories & protein will appear here.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
