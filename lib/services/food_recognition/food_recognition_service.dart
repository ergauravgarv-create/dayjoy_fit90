import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/meals/meal_data.dart';

/// A candidate dish for a meal photo. [confidence] is 0..1: 0 means a
/// suggestion (no image analysis — the user confirms), > 0 means a vision
/// engine actually detected it in the photo.
class FoodGuess {
  const FoodGuess({required this.food, required this.confidence});
  final FoodItem food;
  final double confidence;

  bool get isDetected => confidence > 0;
}

/// Recognises the dish(es) in a meal photo so the user can confirm and log it
/// with nutrition auto-filled from the food database.
///
/// The default build ships [SuggestionFoodRecognizer] — no cost, works on web
/// and offline: it proposes the most common dishes for the meal slot for the
/// user to confirm or search. To enable true auto-recognition of the full
/// ~5,000-dish database, implement this interface against a cloud vision API
/// and return it from [createFoodRecognitionService] — no UI changes needed.
abstract interface class FoodRecognitionService {
  Future<List<FoodGuess>> recognize(Uint8List imageBytes, MealType meal);
}

FoodRecognitionService createFoodRecognitionService() =>
    const SuggestionFoodRecognizer();

final foodRecognitionServiceProvider =
    Provider<FoodRecognitionService>((_) => createFoodRecognitionService());

/// Suggestion-only recogniser: returns popular dishes for the meal slot from
/// the app's food DB. It performs no image analysis (confidence 0) — the user
/// confirms the dish or searches the full list.
class SuggestionFoodRecognizer implements FoodRecognitionService {
  const SuggestionFoodRecognizer();

  @override
  Future<List<FoodGuess>> recognize(Uint8List imageBytes, MealType meal) async {
    // Brief pause so the UI can show an "identifying…" state.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      for (final f in _suggestFor(meal)) FoodGuess(food: f, confidence: 0),
    ];
  }
}

/// Common, recognisable dishes per meal slot (must exist in [kFoodByName];
/// missing names are skipped and topped up from [_keywordsByMeal]).
const Map<MealType, List<String>> _curatedByMeal = {
  MealType.breakfast: [
    'Masala Dosa', 'Plain Dosa', 'Idli', 'Masala Idli', 'Poha', 'Upma',
    'Aloo Paratha', 'Paneer Paratha',
  ],
  MealType.lunch: [
    'Veg Biryani', 'Chicken Biryani', 'Rajma', 'Chole Bhature',
    'Paneer Butter Masala', 'Dal (tadka)', 'Roti / Chapati',
    'Plain Rice (cooked)',
  ],
  MealType.dinner: [
    'Roti / Chapati', 'Dal (tadka)', 'Paneer Butter Masala',
    'Mixed Veg Sabzi', 'Plain Rice (cooked)', 'Rajma', 'Veg Biryani',
    'Chicken Biryani',
  ],
  MealType.snack: [
    'Samosa', 'Poha', 'Upma', 'Masala Idli', 'Chole Bhature', 'Plain Dosa',
  ],
};

/// Category keyword fallback so we always have enough suggestions even if a
/// curated name isn't in the DB.
const Map<MealType, List<String>> _keywordsByMeal = {
  MealType.breakfast: ['breakfast'],
  MealType.lunch: ['rice', 'curr', 'main', 'bread', 'biryani', 'thali', 'wrap', 'roll'],
  MealType.dinner: ['rice', 'curr', 'main', 'bread', 'biryani', 'thali', 'wrap', 'roll'],
  MealType.snack: ['snack', 'street', 'momo', 'chaat', 'pakora', 'samosa', 'bar', 'fries'],
};

List<FoodItem> _suggestFor(MealType meal) {
  final out = <FoodItem>[];
  final seen = <String>{};
  for (final name in _curatedByMeal[meal] ?? const []) {
    final f = kFoodByName[name];
    if (f != null && seen.add(f.name)) out.add(f);
  }
  if (out.length < 8) {
    final kws = _keywordsByMeal[meal] ?? const [];
    for (final f in kAllFoods) {
      if (out.length >= 8) break;
      final c = f.category.toLowerCase();
      if (kws.any(c.contains) && seen.add(f.name)) out.add(f);
    }
  }
  return out;
}
