import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/participant.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/diet_plan_provider.dart';
import 'diet_plan.dart';
import 'food_search_sheet.dart';
import 'meal_data.dart';

/// Doctor/admin screen to author, customise and approve a participant's diet
/// plan. Only staff reach this — participants get the read-only view.
class EditDietPlanScreen extends ConsumerStatefulWidget {
  const EditDietPlanScreen({super.key, required this.participant});
  final Participant participant;

  @override
  ConsumerState<EditDietPlanScreen> createState() =>
      _EditDietPlanScreenState();
}

class _EditDietPlanScreenState extends ConsumerState<EditDietPlanScreen> {
  late final Map<MealType, List<PlanItem>> _meals;
  final TextEditingController _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = ref.read(dietPlanProvider)[widget.participant.id];
    _meals = {for (final t in MealType.values) t: <PlanItem>[]};
    if (existing != null) {
      for (final m in existing.meals) {
        _meals[m.type] = [...m.items];
      }
      _note.text = existing.note;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get _totalKcal => _meals.values
      .expand((l) => l)
      .fold(0, (s, i) => s + i.kcal);
  int get _totalProtein => _meals.values
      .expand((l) => l)
      .fold(0.0, (s, i) => s + i.protein)
      .round();

  void _addFood(MealType type) {
    showFoodSearch(
      context,
      snackbar: false,
      onPick: (food, servings) => setState(() =>
          _meals[type]!.add(PlanItem(foodName: food.name, servings: servings))),
    );
  }

  Future<void> _suggest() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suggest a starting plan?'),
        content: Text(
            'This fills the plan with meals matched to ${widget.participant.name}\'s '
            'goal (~${widget.participant.dailyCalorieGoal} kcal, '
            '${widget.participant.foodPreference}). You can then customise it '
            'before approving. This replaces the current items.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Suggest')),
        ],
      ),
    );
    if (ok != true) return;
    final meals = suggestDietMeals(
      calorieGoal: widget.participant.dailyCalorieGoal,
      isVeg: widget.participant.foodPreference == 'Vegetarian',
    );
    setState(() {
      for (final m in meals) {
        _meals[m.type] = [...m.items];
      }
    });
  }

  void _save(DietPlanStatus status) {
    final plan = DietPlan(
      participantId: widget.participant.id,
      status: status,
      note: _note.text.trim(),
      approvedBy:
          status == DietPlanStatus.approved ? AppConstants.doctorName : null,
      meals: [
        for (final t in MealType.values)
          DietMeal(type: t, items: [..._meals[t]!]),
      ],
    );
    ref.read(dietPlanProvider.notifier).save(plan);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status == DietPlanStatus.approved
            ? 'Plan approved & shared with ${widget.participant.name}'
            : 'Draft saved'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Plan'),
        actions: [
          TextButton.icon(
            onPressed: _suggest,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Suggest'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
        children: [
          GlassCard(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Text(widget.participant.name.characters.first,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.participant.name, style: text.titleMedium),
                      Text(
                          'Goal ~${widget.participant.dailyCalorieGoal} kcal · '
                          '${widget.participant.foodPreference}',
                          style: text.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$_totalKcal kcal',
                        style: text.titleMedium
                            ?.copyWith(color: AppColors.primary)),
                    Text('$_totalProtein g protein', style: text.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final type in MealType.values) ...[
            _EditMealCard(
              type: type,
              items: _meals[type]!,
              onAdd: () => _addFood(type),
              onRemove: (i) => setState(() => _meals[type]!.removeAt(i)),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note for the participant (optional)',
              hintText: 'e.g. Drink 3L water, avoid fried food this week',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _save(DietPlanStatus.draft),
                  child: const Text('Save draft'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _totalKcal > 0
                      ? () => _save(DietPlanStatus.approved)
                      : null,
                  icon: const Icon(Icons.verified_rounded, size: 18),
                  label: const Text('Approve & share'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Only you can create or change this plan. The participant sees it '
            'once you approve.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EditMealCard extends StatelessWidget {
  const _EditMealCard({
    required this.type,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });
  final MealType type;
  final List<PlanItem> items;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int kcal = items.fold(0, (s, i) => s + i.kcal);
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
              Expanded(child: Text(type.label, style: text.titleMedium)),
              if (kcal > 0)
                Text('$kcal kcal',
                    style: text.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text('No items yet — add foods below.',
                  style: text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ),
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      items[i].servings == 1
                          ? items[i].foodName
                          : '${items[i].foodName} ×${_qty(items[i].servings)}',
                      style: text.bodyMedium,
                    ),
                  ),
                  Text('${items[i].kcal}',
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: () => onRemove(i),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAdd,
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
}
