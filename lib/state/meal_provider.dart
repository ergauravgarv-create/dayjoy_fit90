import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/meals/meal_data.dart';
import 'prefs_provider.dart';

/// One logged food: a dish plus how many servings of it were eaten, under a
/// given meal slot.
class MealLog {
  const MealLog({
    required this.id,
    required this.type,
    required this.food,
    required this.servings,
  });

  final int id;
  final MealType type;
  final FoodItem food;
  final double servings;

  int get kcal => (food.kcal * servings).round();
  double get protein => food.protein * servings;
  double get carbs => food.carbs * servings;
  double get fat => food.fat * servings;
  double get fibre => food.fibre * servings;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'servings': servings,
        'food': food.toJson(),
      };

  factory MealLog.fromJson(Map<String, dynamic> j) => MealLog(
        id: (j['id'] as num).toInt(),
        type: MealType.values[(j['type'] as num).toInt()],
        servings: (j['servings'] as num).toDouble(),
        food: FoodItem.fromJson(j['food'] as Map<String, dynamic>),
      );
}

/// Running totals across a set of logs.
class MealTotals {
  const MealTotals({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fibre,
  });

  final int kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fibre;

  static MealTotals of(Iterable<MealLog> logs) {
    int kcal = 0;
    double p = 0, c = 0, f = 0, fb = 0;
    for (final log in logs) {
      kcal += log.kcal;
      p += log.protein;
      c += log.carbs;
      f += log.fat;
      fb += log.fibre;
    }
    return MealTotals(kcal: kcal, protein: p, carbs: c, fat: f, fibre: fb);
  }
}

/// Today's food diary, persisted on-device via SharedPreferences under a
/// per-day key, so it survives app restarts. Each calendar day gets its own
/// diary (past days stay saved; a new day starts fresh). Moving this to the
/// cloud arrives with the Firebase backend.
final mealLogProvider =
    NotifierProvider<MealLogController, List<MealLog>>(MealLogController.new);

/// SharedPreferences key for a given day's diary, e.g. "meal_log_2026-08-01".
String mealLogKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return 'meal_log_${d.year}-$m-$day';
}

/// Decode a stored diary JSON string into logs (empty on null/corrupt).
List<MealLog> decodeMealLogs(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => MealLog.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
}

class MealLogController extends Notifier<List<MealLog>> {
  int _nextId = 0;

  String get _key => mealLogKey(DateTime.now());

  @override
  List<MealLog> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final decoded = decodeMealLogs(prefs.getString(_key));
    if (decoded.isNotEmpty) {
      _nextId = decoded.map((l) => l.id).reduce((a, b) => a > b ? a : b) + 1;
    }
    return decoded;
  }

  void _persist() {
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state.map((l) => l.toJson()).toList()));
  }

  void add(MealType type, FoodItem food, double servings) {
    state = [
      ...state,
      MealLog(id: _nextId++, type: type, food: food, servings: servings),
    ];
    _persist();
  }

  void remove(int id) {
    state = state.where((l) => l.id != id).toList();
    _persist();
  }

  List<MealLog> forMeal(MealType type) =>
      state.where((l) => l.type == type).toList();
}

/// One day's rolled-up nutrition, used by the weekly report.
class DayNutrition {
  const DayNutrition({required this.date, required this.totals});
  final DateTime date;
  final MealTotals totals;

  int get kcal => totals.kcal;
  double get protein => totals.protein;
  bool get logged => totals.kcal > 0;
}

/// Last 7 days of nutrition (oldest → newest, today last). Today comes from the
/// live diary; earlier days are read from their stored per-day keys. Recomputes
/// whenever today's diary changes.
final weeklyNutritionProvider = Provider<List<DayNutrition>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final today = ref.watch(mealLogProvider);
  final now = DateTime.now();
  final base = DateTime(now.year, now.month, now.day);

  final days = <DayNutrition>[];
  for (int i = 6; i >= 0; i--) {
    final date = base.subtract(Duration(days: i));
    final logs =
        i == 0 ? today : decodeMealLogs(prefs.getString(mealLogKey(date)));
    days.add(DayNutrition(date: date, totals: MealTotals.of(logs)));
  }
  return days;
});
