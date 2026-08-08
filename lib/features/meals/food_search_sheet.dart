import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'meal_data.dart';

/// Opens a bottom sheet to search the Indian food table, choose servings, and
/// return the picked food via [onPick]. Shared by the meal tracker and the
/// doctor's diet-plan editor. Optionally restrict the list with [filter]
/// (e.g. veg-only) and show a confirmation snackbar with [snackbar].
Future<void> showFoodSearch(
  BuildContext context, {
  required void Function(FoodItem food, double servings) onPick,
  bool Function(FoodItem)? filter,
  bool snackbar = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceOf(context),
    builder: (_) =>
        _FoodSearchSheet(onPick: onPick, filter: filter, snackbar: snackbar),
  );
}

class _FoodSearchSheet extends StatefulWidget {
  const _FoodSearchSheet({
    required this.onPick,
    required this.snackbar,
    this.filter,
  });
  final void Function(FoodItem food, double servings) onPick;
  final bool Function(FoodItem)? filter;
  final bool snackbar;

  @override
  State<_FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<_FoodSearchSheet> {
  String _query = '';
  String _cat = 'All';

  static const List<String> _catFilters = [
    'All', 'Dayjoy', 'Veg', 'Non-veg', 'Breakfast', 'Mains', 'Snacks',
    'Sweets', 'Drinks',
  ];

  // Keyword buckets that map every food category (base + the imported
  // subcategories like "Rice dishes", "Burgers", "Tea, coffee…") to a chip.
  static const Map<String, List<String>> _chipKeywords = {
    'Breakfast': ['breakfast'],
    'Mains': [
      'main', 'lunch', 'dinner', 'rice', 'curry', 'curries', 'biryani',
      'wrap', 'roll', 'bread', 'roti', 'naan', 'burger', 'pizza', 'taco',
      'pasta', 'noodle', 'indo-chinese', 'dal', 'legume', 'thali', 'gravy',
      'sabzi',
    ],
    'Snacks': [
      'snack', 'starter', 'street food', 'bar', 'momo', 'dumpling', 'chaat',
      'pakora', 'samosa', 'tikki',
    ],
    'Sweets': ['sweet', 'dessert', 'mithai', 'halwa', 'kheer'],
    'Drinks': [
      'drink', 'beverage', 'tea', 'coffee', 'juice', 'shake', 'smoothie',
      'refresher', 'lassi',
    ],
  };

  bool _passesCat(FoodItem f) {
    final String c = f.category.toLowerCase();
    switch (_cat) {
      case 'Dayjoy':
        return c.contains('dayjoy') || c.contains('product');
      case 'Veg':
        return f.isVeg;
      case 'Non-veg':
        return !f.isVeg;
      case 'Breakfast':
      case 'Mains':
      case 'Snacks':
      case 'Sweets':
      case 'Drinks':
        return _chipKeywords[_cat]!.any(c.contains);
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final String q = _query.trim().toLowerCase();
    final List<FoodItem> results = kAllFoods
        .where((f) => widget.filter == null || widget.filter!(f))
        .where(_passesCat)
        .where((f) => q.isEmpty || f.name.toLowerCase().contains(q))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search Indian foods…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: _catFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final String label = _catFilters[i];
                  final bool sel = _cat == label;
                  return ChoiceChip(
                    label: Text(label),
                    selected: sel,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _cat = label),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${results.length} foods',
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text('No match. Try another name.',
                          style: text.bodyMedium))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final f = results[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _VegDot(isVeg: f.isVeg),
                          title: Text(f.name),
                          subtitle: Text(
                              '${f.serving} · P ${f.protein.round()}g · '
                              'C ${f.carbs.round()}g · F ${f.fat.round()}g'),
                          trailing: Text('${f.kcal}',
                              style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          onTap: () => _pickServings(context, f),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickServings(BuildContext context, FoodItem food) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final double? servings = await showDialog<double>(
      context: context,
      builder: (_) => _ServingDialog(food: food),
    );
    if (servings != null && servings > 0) {
      widget.onPick(food, servings);
      navigator.pop(); // close the search sheet
      if (widget.snackbar) {
        messenger.showSnackBar(
          SnackBar(content: Text('${food.name} added')),
        );
      }
    }
  }
}

/// Small green/red square that marks a dish veg or non-veg (Indian packaging
/// convention).
class _VegDot extends StatelessWidget {
  const _VegDot({required this.isVeg});
  final bool isVeg;

  @override
  Widget build(BuildContext context) {
    final Color c = isVeg ? AppColors.success : AppColors.error;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border.all(color: c, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _ServingDialog extends StatefulWidget {
  const _ServingDialog({required this.food});
  final FoodItem food;

  @override
  State<_ServingDialog> createState() => _ServingDialogState();
}

class _ServingDialogState extends State<_ServingDialog> {
  double _servings = 1;

  @override
  Widget build(BuildContext context) {
    final int kcal = (widget.food.kcal * _servings).round();
    return AlertDialog(
      title: Text(widget.food.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('1 serving = ${widget.food.serving}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.filledTonal(
                onPressed: _servings > 0.5
                    ? () => setState(() => _servings -= 0.5)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Column(
                children: [
                  Text(_fmt(_servings),
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text('servings',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              IconButton.filledTonal(
                onPressed: _servings < 20
                    ? () => setState(() => _servings += 0.5)
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('$kcal kcal',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.primary)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_servings),
          child: const Text('Add'),
        ),
      ],
    );
  }

  static String _fmt(double q) =>
      q == q.roundToDouble() ? q.round().toString() : q.toString();
}
