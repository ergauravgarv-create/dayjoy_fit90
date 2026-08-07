import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/participant.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/providers.dart';
import '../../state/repository_providers.dart';
import '../workouts/workout_data.dart';

/// A friendly goal + plan wizard: set target weight, pace, activity and diet,
/// preview a projected timeline and a personalised daily plan, then save.
///
/// In [onboarding] mode it's the first-run step right after registration and
/// continues to the transformation intro; otherwise it's opened from home and
/// pops on save.
class GoalPlanScreen extends ConsumerStatefulWidget {
  const GoalPlanScreen({super.key, this.onboarding = false});
  final bool onboarding;

  @override
  ConsumerState<GoalPlanScreen> createState() => _GoalPlanScreenState();
}

class _GoalPlanScreenState extends ConsumerState<GoalPlanScreen> {
  late double _target;
  late String _activity;
  late String _food;
  double _pace = 0.5; // kg per week
  bool _init = false;
  bool _saving = false;

  static const List<String> _activities = [
    'Sedentary',
    'Light',
    'Moderate',
    'Active',
    'Very active',
  ];

  void _ensureInit(Participant p) {
    if (_init) return;
    _target = p.targetWeightKg > 0 && p.targetWeightKg < p.currentWeightKg
        ? p.targetWeightKg
        : (p.currentWeightKg - 5).clamp(35.0, p.currentWeightKg).toDouble();
    _activity = p.physicalActivityLevel ?? 'Moderate';
    _food = p.foodPreference;
    _init = true;
  }

  Future<void> _save(Participant preview) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(participantRepositoryProvider).upsert(preview);
      ref.invalidate(participantProvider);
      if (!mounted) return;
      if (widget.onboarding) {
        context.go(Routes.transformationIntro);
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Your plan is set — let’s go!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save your plan.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final participant = ref.watch(participantProvider);
    if (participant == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _ensureInit(participant);
    final TextTheme text = Theme.of(context).textTheme;

    final double current = participant.currentWeightKg;
    final double minT = (current - 40).clamp(35.0, current - 1).toDouble();
    final double toLose = (current - _target).clamp(0.0, 999.0).toDouble();

    // Live preview participant reflecting the wizard choices.
    final Participant preview = participant.copyWith(
      targetWeightKg: _target,
      physicalActivityLevel: _activity,
      foodPreference: _food,
    );

    final int weeks = (toLose > 0 && _pace > 0) ? (toLose / _pace).ceil() : 0;
    final DateTime? goalDate =
        weeks > 0 ? DateTime.now().add(Duration(days: weeks * 7)) : null;
    final Intensity intensity = recommendedIntensity(
        bmiCategory: preview.bmiCategory, activityLevel: _activity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your goal & plan'),
        automaticallyImplyLeading: !widget.onboarding,
        actions: [
          if (widget.onboarding)
            TextButton(
              onPressed: () => context.go(Routes.transformationIntro),
              child: const Text('Skip'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: [
          _Step(
            n: 1,
            title: 'Your goal',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current ${current.toStringAsFixed(1)} kg',
                        style: text.bodyMedium),
                    Text('Target ${_target.toStringAsFixed(1)} kg',
                        style: text.titleMedium
                            ?.copyWith(color: AppColors.primary)),
                  ],
                ),
                Slider(
                  value: _target.clamp(minT, current).toDouble(),
                  min: minT,
                  max: current,
                  divisions: (current - minT).round().clamp(1, 200),
                  label: '${_target.toStringAsFixed(1)} kg',
                  onChanged: (v) => setState(() => _target = v),
                ),
                Center(
                  child: Text(
                    toLose > 0
                        ? 'Goal: lose ${toLose.toStringAsFixed(1)} kg'
                        : 'Set a target below your current weight',
                    style: text.bodyMedium?.copyWith(
                        color: AppColors.success, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          _Step(
            n: 2,
            title: 'Your pace',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final p in const [
                      (0.25, 'Gentle'),
                      (0.5, 'Steady'),
                      (0.75, 'Ambitious'),
                    ])
                      ChoiceChip(
                        label: Text('${p.$2} · ${p.$1} kg/wk'),
                        selected: _pace == p.$1,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _pace == p.$1
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _pace = p.$1),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  gradient: AppColors.mixGradient,
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: Colors.white),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          goalDate != null
                              ? 'Reach ${_target.toStringAsFixed(0)} kg in ~$weeks weeks — around ${DateFormat('d MMM yyyy').format(goalDate)}'
                              : 'Pick a target below your current weight to see a timeline',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('A steady 0.5 kg/week is a safe, sustainable pace for most '
                    'people. Your consultant can fine-tune this.',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          _Step(
            n: 3,
            title: 'Activity level',
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final a in _activities)
                  ChoiceChip(
                    label: Text(a),
                    selected: _activity == a,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _activity == a
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _activity = a),
                  ),
              ],
            ),
          ),
          _Step(
            n: 4,
            title: 'Diet preference',
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final f in const ['Vegetarian', 'Non-Vegetarian'])
                  ChoiceChip(
                    label: Text(f),
                    selected: _food == f,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _food == f
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _food = f),
                  ),
              ],
            ),
          ),
          _Step(
            n: 5,
            title: 'Your starting plan',
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _PlanTile(
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.orange,
                    value: '${preview.dailyCalorieGoal}',
                    label: 'kcal / day'),
                _PlanTile(
                    icon: Icons.egg_alt_rounded,
                    color: AppColors.primary,
                    value: '${preview.dailyProteinGoal} g',
                    label: 'protein / day'),
                _PlanTile(
                    icon: Icons.water_drop_rounded,
                    color: AppColors.info,
                    value: '${AppConstants.waterTaskGlasses}',
                    label: 'glasses water'),
                _PlanTile(
                    icon: Icons.directions_walk_rounded,
                    color: AppColors.taskSteps,
                    value: '${(AppConstants.dailyStepGoal / 1000).round()}k',
                    label: 'steps / day'),
                _PlanTile(
                    icon: intensity.icon,
                    color: intensity.color,
                    value: intensity.label,
                    label: 'workout intensity'),
                _PlanTile(
                    icon: Icons.restaurant_menu_rounded,
                    color: AppColors.secondary,
                    value: _food == 'Vegetarian' ? 'Veg' : 'Non-veg',
                    label: 'diet plan'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : () => _save(preview),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded),
              label: Text(_saving
                  ? 'Saving…'
                  : (widget.onboarding ? 'Save & continue' : 'Save my plan')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.title, required this.child});
  final int n;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: AppColors.primary,
                child: Text('$n',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: text.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(child: child),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final double w = (MediaQuery.of(context).size.width - AppSpacing.lg * 2 - 32 - AppSpacing.md) / 2;
    return SizedBox(
      width: w < 120 ? 120 : w,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
