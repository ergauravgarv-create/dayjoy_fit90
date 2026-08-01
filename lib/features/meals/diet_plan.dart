import 'meal_data.dart';

/// A diet plan is authored and approved by the doctor/admin. Participants only
/// view the approved version — they can't edit it.
enum DietPlanStatus { draft, approved }

/// One food line inside a planned meal. Stored by name; macros are looked up
/// from [kFoodByName] so plans stay small and always reflect the latest table.
class PlanItem {
  const PlanItem({required this.foodName, required this.servings});
  final String foodName;
  final double servings;

  FoodItem? get food => kFoodByName[foodName];
  int get kcal => ((food?.kcal ?? 0) * servings).round();
  double get protein => (food?.protein ?? 0) * servings;
  double get carbs => (food?.carbs ?? 0) * servings;
  double get fat => (food?.fat ?? 0) * servings;
  double get fibre => (food?.fibre ?? 0) * servings;

  PlanItem copyWith({double? servings}) =>
      PlanItem(foodName: foodName, servings: servings ?? this.servings);

  Map<String, dynamic> toJson() => {'name': foodName, 'servings': servings};
  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
        foodName: j['name'] as String,
        servings: (j['servings'] as num).toDouble(),
      );
}

/// A planned meal (Breakfast/Lunch/Dinner/Snack) and its food lines.
class DietMeal {
  const DietMeal({required this.type, required this.items});
  final MealType type;
  final List<PlanItem> items;

  int get kcal => items.fold(0, (s, i) => s + i.kcal);
  double get protein => items.fold(0.0, (s, i) => s + i.protein);
  double get carbs => items.fold(0.0, (s, i) => s + i.carbs);
  double get fat => items.fold(0.0, (s, i) => s + i.fat);
  double get fibre => items.fold(0.0, (s, i) => s + i.fibre);

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'items': items.map((i) => i.toJson()).toList(),
      };
  factory DietMeal.fromJson(Map<String, dynamic> j) => DietMeal(
        type: MealType.values[(j['type'] as num).toInt()],
        items: (j['items'] as List)
            .map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// A participant's full diet plan.
class DietPlan {
  const DietPlan({
    required this.participantId,
    required this.meals,
    required this.status,
    this.note = '',
    this.approvedBy,
  });

  final String participantId;
  final List<DietMeal> meals;
  final DietPlanStatus status;
  final String note;
  final String? approvedBy;

  bool get isApproved => status == DietPlanStatus.approved;
  int get totalKcal => meals.fold(0, (s, m) => s + m.kcal);
  double get totalProtein => meals.fold(0.0, (s, m) => s + m.protein);

  DietPlan copyWith({
    List<DietMeal>? meals,
    DietPlanStatus? status,
    String? note,
    String? approvedBy,
  }) =>
      DietPlan(
        participantId: participantId,
        meals: meals ?? this.meals,
        status: status ?? this.status,
        note: note ?? this.note,
        approvedBy: approvedBy ?? this.approvedBy,
      );

  Map<String, dynamic> toJson() => {
        'participantId': participantId,
        'status': status.index,
        'note': note,
        'approvedBy': approvedBy,
        'meals': meals.map((m) => m.toJson()).toList(),
      };
  factory DietPlan.fromJson(Map<String, dynamic> j) => DietPlan(
        participantId: j['participantId'] as String,
        status: DietPlanStatus.values[(j['status'] as num).toInt()],
        note: (j['note'] as String?) ?? '',
        approvedBy: j['approvedBy'] as String?,
        meals: (j['meals'] as List)
            .map((e) => DietMeal.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// An empty editable plan for a participant.
  factory DietPlan.empty(String participantId) => DietPlan(
        participantId: participantId,
        status: DietPlanStatus.draft,
        meals: [
          for (final t in MealType.values) DietMeal(type: t, items: const []),
        ],
      );
}

// ---------------------------------------------------------------------------
// Suggestion generator — a DOCTOR tool to pre-fill a starting plan that fits
// the participant's calorie goal and veg/non-veg preference. The doctor then
// customises and approves it; participants never see the raw generator output.
// ---------------------------------------------------------------------------

typedef _Template = List<(String, num)>; // (food name, servings)

const Map<MealType, double> _mealShare = {
  MealType.breakfast: 0.25,
  MealType.lunch: 0.35,
  MealType.dinner: 0.30,
  MealType.snack: 0.10,
};

const Map<MealType, List<_Template>> _vegTemplates = {
  MealType.breakfast: [
    [('Poha', 1), ('Masala Chai (with sugar)', 1)],
    [('Idli', 1), ('Sambar', 1)],
    [('Masala Dosa', 1), ('Sambar', 1)],
    [('Aloo Paratha', 1), ('Curd / Dahi', 1)],
    [('Upma', 1), ('Milk (toned)', 1)],
    [('Ample Meal Shake', 2), ('Banana', 1)],
  ],
  MealType.lunch: [
    [('Roti / Chapati', 3), ('Dal (tadka)', 1), ('Mixed Veg Sabzi', 1), ('Green Salad', 1)],
    [('Plain Rice (cooked)', 1), ('Rajma', 1), ('Curd / Dahi', 1), ('Green Salad', 1)],
    [('Roti / Chapati', 2), ('Chole / Chana Masala', 1), ('Curd / Dahi', 1), ('Green Salad', 1)],
    [('Veg Biryani', 1), ('Curd / Dahi', 1)],
    [('Roti / Chapati', 2), ('Palak Paneer', 1), ('Green Salad', 1)],
  ],
  MealType.dinner: [
    [('Roti / Chapati', 2), ('Dal (tadka)', 1), ('Bhindi Masala', 1)],
    [('Khichdi', 1), ('Curd / Dahi', 1)],
    [('Roti / Chapati', 2), ('Palak Paneer', 1), ('Green Salad', 1)],
    [('Plain Rice (cooked)', 1), ('Sambar', 1), ('Green Salad', 1)],
  ],
  MealType.snack: [
    [('Sprouts (moong)', 1)],
    [('Roasted Chana', 1)],
    [('Mixed Fruit Bowl', 1)],
    [('Vital Protein', 1), ('Milk (toned)', 1)],
  ],
};

const Map<MealType, List<_Template>> _nonVegExtras = {
  MealType.breakfast: [
    [('Omelette (2 egg)', 1), ('Bread slice (white)', 2)],
    [('Boiled Egg', 2), ('Bread slice (white)', 2), ('Milk (toned)', 1)],
  ],
  MealType.lunch: [
    [('Plain Rice (cooked)', 1), ('Chicken Curry', 1), ('Green Salad', 1)],
    [('Roti / Chapati', 2), ('Grilled Chicken', 1.5), ('Green Salad', 1)],
    [('Plain Rice (cooked)', 1), ('Fish Curry', 1), ('Green Salad', 1)],
  ],
  MealType.dinner: [
    [('Roti / Chapati', 2), ('Fish Curry', 1), ('Green Salad', 1)],
    [('Roti / Chapati', 2), ('Chicken Curry', 1), ('Green Salad', 1)],
  ],
  MealType.snack: [
    [('Boiled Egg', 2)],
  ],
};

int _templateKcal(_Template t) => t.fold(
    0, (s, e) => s + (((kFoodByName[e.$1]?.kcal ?? 0)) * e.$2).round());

/// Build a suggested set of meals that roughly matches [calorieGoal].
/// [daySeed] rotates among the closest options so repeat calls can vary.
List<DietMeal> suggestDietMeals({
  required int calorieGoal,
  required bool isVeg,
  int daySeed = 0,
}) {
  final List<DietMeal> meals = [];
  for (final type in MealType.values) {
    final target = (calorieGoal * (_mealShare[type] ?? 0.25)).round();
    final pool = <_Template>[
      ...?_vegTemplates[type],
      if (!isVeg) ...?_nonVegExtras[type],
    ];
    if (pool.isEmpty) {
      meals.add(DietMeal(type: type, items: const []));
      continue;
    }
    // Nearest few to the target, then rotate by the seed for variety.
    final sorted = [...pool]
      ..sort((a, b) =>
          (_templateKcal(a) - target).abs() - (_templateKcal(b) - target).abs());
    final topN = sorted.take(3).toList();
    final chosen = topN[daySeed % topN.length];
    meals.add(DietMeal(
      type: type,
      items: [
        for (final e in chosen)
          PlanItem(foodName: e.$1, servings: e.$2.toDouble())
      ],
    ));
  }
  return meals;
}
