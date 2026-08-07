import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/diet_chart_provider.dart';
import '../../state/diet_plan_provider.dart';
import '../../state/meal_provider.dart';
import '../../state/providers.dart';
import '../diet_charts/diet_chart_detail_screen.dart';
import 'diet_plan.dart';
import 'meal_data.dart';

/// Read-only view of the participant's doctor-approved diet plan. Participants
/// can log meals from it but cannot edit it — customisation is doctor/admin only.
class MyDietPlanScreen extends ConsumerStatefulWidget {
  const MyDietPlanScreen({super.key});

  @override
  ConsumerState<MyDietPlanScreen> createState() => _MyDietPlanScreenState();
}

class _MyDietPlanScreenState extends ConsumerState<MyDietPlanScreen> {
  void _logMeal(DietMeal meal) {
    final notifier = ref.read(mealLogProvider.notifier);
    for (final item in meal.items) {
      final food = item.food;
      if (food != null) notifier.add(meal.type, food, item.servings);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${meal.type.label} added to your diary')),
    );
  }

  void _logWholeDay(DietPlan plan) {
    final notifier = ref.read(mealLogProvider.notifier);
    for (final meal in plan.meals) {
      for (final item in meal.items) {
        final food = item.food;
        if (food != null) notifier.add(meal.type, food, item.servings);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Full day added to your diary')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(participantProvider);

    // A consultant-assigned clinical diet chart takes priority.
    final String? chartId =
        p == null ? null : ref.watch(assignedChartProvider)[p.id];
    if (chartId != null) {
      final chartsAsync = ref.watch(dietChartsProvider);
      final charts = chartsAsync.valueOrNull;
      if (charts != null) {
        for (final c in charts) {
          if (c.id == chartId) {
            return Scaffold(
              appBar: AppBar(title: const Text('My Diet Chart')),
              body: DietChartView(chart: c, consultant: false),
            );
          }
        }
      } else if (chartsAsync.isLoading) {
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      }
    }

    final plan = p == null ? null : ref.watch(dietPlanProvider)[p.id];
    final bool ready = plan != null && plan.isApproved;

    return Scaffold(
      appBar: AppBar(title: const Text('My Diet Plan')),
      body: !ready
          ? const _PreparingState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
              children: [
                _PlanHeader(plan: plan, onLogAll: () => _logWholeDay(plan)),
                const SizedBox(height: AppSpacing.lg),
                for (final meal in plan.meals)
                  if (meal.items.isNotEmpty) ...[
                    _PlanMealCard(meal: meal, onLog: () => _logMeal(meal)),
                    const SizedBox(height: AppSpacing.md),
                  ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'This plan is prepared and approved by your doctor. To change '
                  'it, message your care team.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}

class _PreparingState extends StatelessWidget {
  const _PreparingState();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_menu_rounded,
                size: 64, color: AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text('Your plan is on the way', style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Dr. Prachita is preparing your personalised diet plan. '
              'You\'ll see it here as soon as it\'s approved.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.plan, required this.onLogAll});
  final DietPlan plan;
  final VoidCallback onLogAll;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: AppColors.brandGradient,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Approved by ${plan.approvedBy ?? 'your doctor'}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('${plan.totalKcal}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('kcal / day',
                    style: TextStyle(color: Colors.white70)),
              ),
              const Spacer(),
              Text('${plan.totalProtein.round()} g protein',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
          if (plan.note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(plan.note,
                style: const TextStyle(color: Colors.white70, height: 1.3)),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              onPressed: onLogAll,
              icon: const Icon(Icons.playlist_add_check_rounded),
              label: const Text('Log the whole day'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanMealCard extends StatelessWidget {
  const _PlanMealCard({required this.meal, required this.onLog});
  final DietMeal meal;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Icon(meal.type.icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(meal.type.label, style: text.titleMedium)),
              Text('${meal.kcal} kcal',
                  style:
                      text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in meal.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Text('•  '),
                  Expanded(
                    child: Text(
                      item.servings == 1
                          ? item.foodName
                          : '${item.foodName} ×${_qty(item.servings)}',
                      style: text.bodyMedium,
                    ),
                  ),
                  Text('${item.kcal}',
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onLog,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Log this meal'),
            ),
          ),
        ],
      ),
    );
  }

  static String _qty(double q) =>
      q == q.roundToDouble() ? q.round().toString() : q.toString();
}
