import 'package:flutter/material.dart';

/// The four meal slots a food can be logged under.
enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeX on MealType {
  String get label => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snacks',
      };

  IconData get icon => switch (this) {
        MealType.breakfast => Icons.free_breakfast_rounded,
        MealType.lunch => Icons.lunch_dining_rounded,
        MealType.dinner => Icons.dinner_dining_rounded,
        MealType.snack => Icons.bakery_dining_rounded,
      };
}

/// A single Indian dish with per-serving nutrition. Values are built-in
/// estimates for common home-style Indian portions — good enough to guide
/// habits, not a clinical measurement. (Swapping this for a live AI/nutrition
/// API later only means changing where `kIndianFoods` is sourced from.)
class FoodItem {
  const FoodItem({
    required this.name,
    required this.serving,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fibre,
    this.isVeg = true,
  });

  final String name;

  /// Human-readable portion this row is measured for, e.g. "1 roti (~30g)".
  final String serving;
  final int kcal;
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams
  final double fibre; // grams

  /// Whether this dish is vegetarian (eggs & meat/fish are marked non-veg).
  final bool isVeg;

  Map<String, dynamic> toJson() => {
        'name': name,
        'serving': serving,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fibre': fibre,
        'isVeg': isVeg,
      };

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
        name: j['name'] as String,
        serving: j['serving'] as String,
        kcal: (j['kcal'] as num).toInt(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
        fibre: (j['fibre'] as num).toDouble(),
        isVeg: (j['isVeg'] as bool?) ?? true,
      );
}

/// Soft daily goals shown as progress on the meal tracker (weight-loss tuned).
const int kCalorieGoal = 1600;
const int kProteinGoal = 65; // grams

/// A curated table of ~70 common Indian foods. Alphabetical-ish by group.
const List<FoodItem> kIndianFoods = [
  // ---- Rotis & breads ----
  FoodItem(name: 'Roti / Chapati', serving: '1 medium (~30g)', kcal: 80, protein: 3, carbs: 15, fat: 1, fibre: 2),
  FoodItem(name: 'Phulka (no oil)', serving: '1 (~25g)', kcal: 70, protein: 2.5, carbs: 14, fat: 0.5, fibre: 2),
  FoodItem(name: 'Tandoori Roti', serving: '1 (~45g)', kcal: 120, protein: 4, carbs: 24, fat: 1.5, fibre: 3),
  FoodItem(name: 'Butter Naan', serving: '1 (~90g)', kcal: 290, protein: 8, carbs: 45, fat: 9, fibre: 2),
  FoodItem(name: 'Paratha (plain)', serving: '1 (~60g)', kcal: 210, protein: 4, carbs: 28, fat: 9, fibre: 2),
  FoodItem(name: 'Aloo Paratha', serving: '1 (~120g)', kcal: 290, protein: 6, carbs: 40, fat: 12, fibre: 3),
  FoodItem(name: 'Bhatura', serving: '1 (~80g)', kcal: 300, protein: 6, carbs: 40, fat: 13, fibre: 1),
  FoodItem(name: 'Puri', serving: '1 (~25g)', kcal: 100, protein: 2, carbs: 12, fat: 5, fibre: 1),
  FoodItem(name: 'Bread slice (white)', serving: '1 slice', kcal: 70, protein: 2, carbs: 13, fat: 1, fibre: 1),

  // ---- Rice & grains ----
  FoodItem(name: 'Plain Rice (cooked)', serving: '1 katori (~150g)', kcal: 200, protein: 4, carbs: 44, fat: 0.5, fibre: 1),
  FoodItem(name: 'Jeera Rice', serving: '1 katori (~150g)', kcal: 240, protein: 4, carbs: 45, fat: 5, fibre: 1),
  FoodItem(name: 'Veg Biryani', serving: '1 plate (~250g)', kcal: 350, protein: 8, carbs: 55, fat: 11, fibre: 4),
  FoodItem(name: 'Chicken Biryani', serving: '1 plate (~300g)', kcal: 480, protein: 22, carbs: 55, fat: 18, fibre: 3, isVeg: false),
  FoodItem(name: 'Curd Rice', serving: '1 katori (~200g)', kcal: 230, protein: 6, carbs: 38, fat: 6, fibre: 1),
  FoodItem(name: 'Lemon Rice', serving: '1 katori (~180g)', kcal: 270, protein: 5, carbs: 42, fat: 9, fibre: 2),
  FoodItem(name: 'Khichdi', serving: '1 katori (~200g)', kcal: 250, protein: 9, carbs: 40, fat: 6, fibre: 4),
  FoodItem(name: 'Poha', serving: '1 plate (~150g)', kcal: 250, protein: 5, carbs: 40, fat: 8, fibre: 2),
  FoodItem(name: 'Upma', serving: '1 plate (~150g)', kcal: 250, protein: 6, carbs: 38, fat: 8, fibre: 2),

  // ---- Dals & legumes ----
  FoodItem(name: 'Dal (tadka)', serving: '1 katori (~150g)', kcal: 150, protein: 9, carbs: 20, fat: 4, fibre: 5),
  FoodItem(name: 'Dal Makhani', serving: '1 katori (~150g)', kcal: 280, protein: 11, carbs: 24, fat: 15, fibre: 6),
  FoodItem(name: 'Rajma', serving: '1 katori (~150g)', kcal: 210, protein: 11, carbs: 30, fat: 5, fibre: 8),
  FoodItem(name: 'Chole / Chana Masala', serving: '1 katori (~150g)', kcal: 240, protein: 11, carbs: 32, fat: 8, fibre: 9),
  FoodItem(name: 'Sambar', serving: '1 katori (~150g)', kcal: 130, protein: 6, carbs: 18, fat: 4, fibre: 4),
  FoodItem(name: 'Sprouts (moong)', serving: '1 katori (~100g)', kcal: 100, protein: 7, carbs: 16, fat: 1, fibre: 5),

  // ---- Sabzis / vegetables ----
  FoodItem(name: 'Mixed Veg Sabzi', serving: '1 katori (~150g)', kcal: 150, protein: 4, carbs: 16, fat: 8, fibre: 5),
  FoodItem(name: 'Aloo Gobi', serving: '1 katori (~150g)', kcal: 170, protein: 4, carbs: 20, fat: 9, fibre: 5),
  FoodItem(name: 'Bhindi Masala', serving: '1 katori (~150g)', kcal: 160, protein: 3, carbs: 14, fat: 10, fibre: 6),
  FoodItem(name: 'Palak Paneer', serving: '1 katori (~150g)', kcal: 250, protein: 12, carbs: 12, fat: 18, fibre: 4),
  FoodItem(name: 'Paneer Butter Masala', serving: '1 katori (~150g)', kcal: 320, protein: 13, carbs: 14, fat: 24, fibre: 3),
  FoodItem(name: 'Baingan Bharta', serving: '1 katori (~150g)', kcal: 150, protein: 3, carbs: 14, fat: 9, fibre: 5),
  FoodItem(name: 'Green Salad', serving: '1 plate (~100g)', kcal: 40, protein: 2, carbs: 8, fat: 0.5, fibre: 3),

  // ---- Paneer / eggs / non-veg ----
  FoodItem(name: 'Paneer (raw)', serving: '50g', kcal: 130, protein: 9, carbs: 2, fat: 10, fibre: 0),
  FoodItem(name: 'Boiled Egg', serving: '1 egg', kcal: 78, protein: 6, carbs: 0.6, fat: 5, fibre: 0, isVeg: false),
  FoodItem(name: 'Egg Bhurji', serving: '2 eggs (~130g)', kcal: 220, protein: 13, carbs: 4, fat: 17, fibre: 1, isVeg: false),
  FoodItem(name: 'Omelette (2 egg)', serving: '~130g', kcal: 230, protein: 13, carbs: 2, fat: 18, fibre: 0, isVeg: false),
  FoodItem(name: 'Chicken Curry', serving: '1 katori (~150g)', kcal: 260, protein: 24, carbs: 6, fat: 16, fibre: 1, isVeg: false),
  FoodItem(name: 'Grilled Chicken', serving: '100g', kcal: 165, protein: 31, carbs: 0, fat: 4, fibre: 0, isVeg: false),
  FoodItem(name: 'Chicken Tikka', serving: '4 pieces (~120g)', kcal: 220, protein: 27, carbs: 4, fat: 11, fibre: 0, isVeg: false),
  FoodItem(name: 'Fish Curry', serving: '1 katori (~150g)', kcal: 220, protein: 22, carbs: 6, fat: 12, fibre: 1, isVeg: false),
  FoodItem(name: 'Mutton Curry', serving: '1 katori (~150g)', kcal: 320, protein: 22, carbs: 6, fat: 23, fibre: 1, isVeg: false),

  // ---- South Indian ----
  FoodItem(name: 'Idli', serving: '2 pieces', kcal: 140, protein: 5, carbs: 28, fat: 1, fibre: 2),
  FoodItem(name: 'Plain Dosa', serving: '1 (~90g)', kcal: 170, protein: 4, carbs: 28, fat: 5, fibre: 2),
  FoodItem(name: 'Masala Dosa', serving: '1 (~150g)', kcal: 290, protein: 6, carbs: 44, fat: 10, fibre: 3),
  FoodItem(name: 'Medu Vada', serving: '1 (~45g)', kcal: 140, protein: 4, carbs: 16, fat: 7, fibre: 2),
  FoodItem(name: 'Uttapam', serving: '1 (~120g)', kcal: 210, protein: 6, carbs: 34, fat: 6, fibre: 3),

  // ---- Snacks & street food ----
  FoodItem(name: 'Samosa', serving: '1 (~60g)', kcal: 260, protein: 4, carbs: 28, fat: 15, fibre: 2),
  FoodItem(name: 'Pakora / Bhaji', serving: '1 plate (~100g)', kcal: 300, protein: 6, carbs: 26, fat: 19, fibre: 3),
  FoodItem(name: 'Dhokla', serving: '2 pieces (~100g)', kcal: 160, protein: 6, carbs: 24, fat: 4, fibre: 2),
  FoodItem(name: 'Vada Pav', serving: '1', kcal: 290, protein: 7, carbs: 42, fat: 11, fibre: 3),
  FoodItem(name: 'Pav Bhaji', serving: '1 plate (~250g)', kcal: 400, protein: 9, carbs: 52, fat: 17, fibre: 6),
  FoodItem(name: 'Pani Puri', serving: '6 pieces', kcal: 180, protein: 3, carbs: 30, fat: 5, fibre: 2),
  FoodItem(name: 'Bhel Puri', serving: '1 plate (~120g)', kcal: 220, protein: 5, carbs: 34, fat: 8, fibre: 3),
  FoodItem(name: 'Peanuts (roasted)', serving: 'handful (~30g)', kcal: 170, protein: 8, carbs: 5, fat: 14, fibre: 3),
  FoodItem(name: 'Roasted Chana', serving: 'handful (~30g)', kcal: 120, protein: 6, carbs: 18, fat: 2, fibre: 5),
  FoodItem(name: 'Biscuit (marie)', serving: '2 pieces', kcal: 90, protein: 1.5, carbs: 15, fat: 3, fibre: 0.5),

  // ---- Dairy & drinks ----
  FoodItem(name: 'Milk (toned)', serving: '1 glass (200ml)', kcal: 120, protein: 6, carbs: 10, fat: 6, fibre: 0),
  FoodItem(name: 'Curd / Dahi', serving: '1 katori (~150g)', kcal: 100, protein: 6, carbs: 8, fat: 5, fibre: 0),
  FoodItem(name: 'Buttermilk / Chaas', serving: '1 glass (200ml)', kcal: 60, protein: 3, carbs: 6, fat: 2, fibre: 0),
  FoodItem(name: 'Lassi (sweet)', serving: '1 glass (250ml)', kcal: 220, protein: 6, carbs: 32, fat: 7, fibre: 0),
  FoodItem(name: 'Masala Chai (with sugar)', serving: '1 cup (150ml)', kcal: 90, protein: 2, carbs: 12, fat: 3, fibre: 0),
  FoodItem(name: 'Black Coffee (no sugar)', serving: '1 cup', kcal: 5, protein: 0.3, carbs: 0, fat: 0, fibre: 0),
  FoodItem(name: 'Coconut Water', serving: '1 glass (200ml)', kcal: 45, protein: 1.5, carbs: 9, fat: 0.5, fibre: 2.5),

  // ---- Fruits ----
  FoodItem(name: 'Banana', serving: '1 medium', kcal: 100, protein: 1.3, carbs: 27, fat: 0.3, fibre: 3),
  FoodItem(name: 'Apple', serving: '1 medium', kcal: 95, protein: 0.5, carbs: 25, fat: 0.3, fibre: 4),
  FoodItem(name: 'Papaya', serving: '1 katori (~150g)', kcal: 65, protein: 1, carbs: 16, fat: 0.4, fibre: 2.5),
  FoodItem(name: 'Orange', serving: '1 medium', kcal: 62, protein: 1.2, carbs: 15, fat: 0.2, fibre: 3),
  FoodItem(name: 'Mixed Fruit Bowl', serving: '1 bowl (~150g)', kcal: 90, protein: 1.5, carbs: 22, fat: 0.4, fibre: 4),

  // ---- Dayjoy program items ----
  FoodItem(name: 'Ample Meal Shake', serving: '25g scoop', kcal: 100, protein: 8, carbs: 12, fat: 2, fibre: 3),
  FoodItem(name: 'Vital Protein', serving: '10g scoop', kcal: 40, protein: 9, carbs: 0.5, fat: 0.3, fibre: 0),
  FoodItem(name: 'Whey Protein Scoop', serving: '30g scoop', kcal: 120, protein: 24, carbs: 3, fat: 1.5, fibre: 0),
];

/// Fast lookup by dish name (used to rebuild diet-plan items from stored names).
final Map<String, FoodItem> kFoodByName = {
  for (final f in kIndianFoods) f.name: f,
};
