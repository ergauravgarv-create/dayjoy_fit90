import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/participant.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/meal_photos_provider.dart';
import '../../state/meal_provider.dart';
import '../../state/providers.dart';
import 'food_diary_screen.dart';
import 'food_search_sheet.dart';
import 'meal_data.dart';
import 'weekly_nutrition_screen.dart';

class MealTrackerScreen extends ConsumerWidget {
  const MealTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(mealLogProvider);
    final totals = MealTotals.of(logs);
    final participant = ref.watch(participantProvider);
    final int calorieGoal = participant?.dailyCalorieGoal ?? kCalorieGoal;
    final int proteinGoal = participant?.dailyProteinGoal ?? kProteinGoal;
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Tracker'),
        actions: [
          IconButton(
            tooltip: 'Food diary',
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const FoodDiaryScreen()),
            ),
          ),
          IconButton(
            tooltip: 'This week',
            icon: const Icon(Icons.insights_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const WeeklyNutritionScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
        children: [
          _SummaryCard(
              totals: totals,
              calorieGoal: calorieGoal,
              proteinGoal: proteinGoal,
              participant: participant),
          const SizedBox(height: AppSpacing.xl),
          for (final type in MealType.values) ...[
            _MealSection(
              type: type,
              logs: logs.where((l) => l.type == type).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Calorie & macro values are built-in estimates for typical Indian '
            'home portions — a helpful guide, not a clinical measurement.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totals,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.participant,
  });
  final MealTotals totals;
  final int calorieGoal;
  final int proteinGoal;
  final Participant? participant;

  @override
  Widget build(BuildContext context) {
    final double calPct =
        (totals.kcal / calorieGoal).clamp(0.0, 1.0).toDouble();
    final int remaining = calorieGoal - totals.kcal;

    return GlassCard(
      gradient: AppColors.brandGradient,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${totals.kcal}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/ $calorieGoal kcal',
                    style: const TextStyle(color: Colors.white70)),
              ),
              const Spacer(),
              Text(
                remaining >= 0 ? '$remaining left' : '${-remaining} over',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: calPct,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _Macro(
                  label: 'Protein',
                  value: totals.protein,
                  goal: proteinGoal.toDouble()),
              _Macro(label: 'Carbs', value: totals.carbs),
              _Macro(label: 'Fat', value: totals.fat),
              _Macro(label: 'Fibre', value: totals.fibre),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: Colors.white.withOpacity(0.25), height: 1),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () => _showGoalInfo(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.info_outline_rounded,
                    color: Colors.white70, size: 16),
                SizedBox(width: 6),
                Text('How we calculated your goal',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalInfo(BuildContext context) {
    final p = participant;
    final bool losing = p != null && p.targetWeightKg < p.currentWeightKg;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceOf(context),
      builder: (ctx) {
        final TextTheme t = Theme.of(ctx).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How your goal is calculated', style: t.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Text(
                p == null
                    ? 'Once you complete your profile, we personalise these '
                        'goals from your age, height, weight, gender and '
                        'activity level.'
                    : 'Your goals are personalised from your profile — not a '
                        'one-size-fits-all number.',
                style: t.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (p != null) ...[
                _InfoRow(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Maintenance: ~${p.maintenanceCalories} kcal',
                  body:
                      'The energy to keep your current weight, from your age, '
                      'height, ${p.currentWeightKg.round()} kg, gender and '
                      '"${p.physicalActivityLevel ?? 'Moderate'}" activity '
                      '(Mifflin–St Jeor formula).',
                ),
                _InfoRow(
                  icon: Icons.flag_rounded,
                  title: 'Your goal: $calorieGoal kcal',
                  body: losing
                      ? 'Because you\'re aiming for ${p.targetWeightKg.round()} '
                          'kg, we take about 500 kcal off maintenance — a steady '
                          '~0.5 kg per week, never below a safe minimum.'
                      : 'You\'re set to maintain your weight, so your goal '
                          'matches your maintenance calories.',
                ),
                _InfoRow(
                  icon: Icons.egg_alt_rounded,
                  title: 'Protein: $proteinGoal g',
                  body: 'About 1.6 g per kg of body weight to protect muscle '
                      'while you lose fat.',
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                'These are healthy estimates. Your coach or doctor can '
                'fine-tune them for you.',
                style: t.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body, style: t.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.value, this.goal});
  final String label;
  final double value;
  final double? goal;

  @override
  Widget build(BuildContext context) {
    final String text = goal == null
        ? '${value.round()}g'
        : '${value.round()}/${goal!.round()}g';
    return Expanded(
      child: Column(
        children: [
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MealSection extends ConsumerWidget {
  const _MealSection({required this.type, required this.logs});
  final MealType type;
  final List<MealLog> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final int kcal = logs.fold(0, (s, l) => s + l.kcal);
    final String? photo = ref.watch(mealPhotosProvider)[type];

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
                child: Icon(type.icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(type.label, style: text.titleMedium),
              ),
              if (kcal > 0)
                Text('$kcal kcal',
                    style: text.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Photo of your ${type.label.toLowerCase()}',
                icon: Icon(
                    photo == null
                        ? Icons.photo_camera_outlined
                        : Icons.photo_camera_rounded,
                    color: AppColors.primary),
                onPressed: () => photo == null
                    ? _capturePhoto(context, ref, type)
                    : _photoOptions(context, ref, type, photo),
              ),
            ],
          ),
          if (photo != null) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => _viewPhoto(context, photo),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.memory(
                  base64Decode(photo),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          if (logs.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          for (final log in logs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.servings == 1
                              ? log.food.name
                              : '${log.food.name} ×${_qty(log.servings)}',
                          style: text.bodyMedium,
                        ),
                        Text(
                            'P ${log.protein.round()} · C ${log.carbs.round()} · '
                            'F ${log.fat.round()} · Fib ${log.fibre.round()} g',
                            style: text.bodySmall?.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${log.kcal}',
                      style: text.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: () =>
                        ref.read(mealLogProvider.notifier).remove(log.id),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openFoodSearch(context, ref, type),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text('Add to ${type.label.toLowerCase()}'),
            ),
          ),
        ],
      ),
    );
  }

  static String _qty(double q) =>
      q == q.roundToDouble() ? q.round().toString() : q.toString();

  void _openFoodSearch(BuildContext context, WidgetRef ref, MealType type) {
    showFoodSearch(
      context,
      onPick: (food, servings) =>
          ref.read(mealLogProvider.notifier).add(type, food, servings),
    );
  }

  Future<void> _capturePhoto(
      BuildContext context, WidgetRef ref, MealType type,
      {ImageSource source = ImageSource.camera}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final XFile? x = await ImagePicker()
          .pickImage(source: source, maxWidth: 1280, imageQuality: 70);
      if (x != null) {
        final bytes = await x.readAsBytes();
        ref
            .read(mealPhotosProvider.notifier)
            .setPhoto(type, base64Encode(bytes));
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not add the photo on this device.')),
      );
    }
  }

  void _viewPhoto(BuildContext context, String data) {
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

  void _photoOptions(
      BuildContext context, WidgetRef ref, MealType type, String data) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceOf(context),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.fullscreen_rounded),
              title: const Text('View photo'),
              onTap: () {
                Navigator.pop(ctx);
                _viewPhoto(context, data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Retake with camera'),
              onTap: () {
                Navigator.pop(ctx);
                _capturePhoto(context, ref, type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _capturePhoto(context, ref, type,
                    source: ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              title: const Text('Remove photo'),
              onTap: () {
                ref.read(mealPhotosProvider.notifier).removePhoto(type);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
