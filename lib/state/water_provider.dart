import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_provider.dart';

/// Millilitres in one "glass" — the unit the daily task & challenges count in.
const int kGlassMl = 250;

/// Common cup sizes (ml) for the quick-add buttons.
const List<int> kCupSizes = [150, 250, 330, 500, 750];

/// Legacy per-day key that stored a glass COUNT (int). Kept for migration.
String waterKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return 'water_${d.year}-$m-$day';
}

/// Per-day key storing millilitres (the new source of truth).
String waterMlKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return 'waterml_${d.year}-$m-$day';
}

/// Reads a day's ml, migrating from the legacy glass count when needed.
int _mlForDay(SharedPreferences prefs, DateTime d) {
  final ml = prefs.getInt(waterMlKey(d));
  if (ml != null) return ml;
  final glasses = prefs.getInt(waterKey(d));
  return glasses != null ? glasses * kGlassMl : 0;
}

/// Today's water intake in **millilitres**, persisted per day (survives
/// restarts; each calendar day starts fresh).
final waterMlProvider =
    NotifierProvider<WaterController, int>(WaterController.new);

class WaterController extends Notifier<int> {
  String get _key => waterMlKey(DateTime.now());

  @override
  int build() =>
      _mlForDay(ref.watch(sharedPreferencesProvider), DateTime.now());

  void _persist() => ref.read(sharedPreferencesProvider).setInt(_key, state);

  void addMl(int ml) {
    state = (state + ml).clamp(0, 10000).toInt();
    _persist();
  }

  void removeMl(int ml) {
    state = (state - ml).clamp(0, 10000).toInt();
    _persist();
  }

  void addGlass() => addMl(kGlassMl);
  void removeGlass() => removeMl(kGlassMl);

  void reset() {
    state = 0;
    _persist();
  }
}

/// Today's intake expressed in whole glasses — the unit the daily task and
/// weekly challenges count in. Derived so all existing screens keep working.
final waterProvider =
    Provider<int>((ref) => ref.watch(waterMlProvider) ~/ kGlassMl);

/// The participant's personal daily hydration goal in ml (default 3 L),
/// persisted. Separate from the fixed 12-glass daily *task* threshold.
final waterGoalMlProvider =
    NotifierProvider<WaterGoalController, int>(WaterGoalController.new);

class WaterGoalController extends Notifier<int> {
  static const String _key = 'water_goal_ml';

  @override
  int build() => ref.watch(sharedPreferencesProvider).getInt(_key) ?? 3000;

  void setGoal(int ml) {
    state = ml.clamp(1000, 6000).toInt();
    ref.read(sharedPreferencesProvider).setInt(_key, state);
  }
}

/// Glasses of water for the last 7 days (oldest → newest, today last).
final weeklyWaterProvider = Provider<List<int>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final todayMl = ref.watch(waterMlProvider);
  final now = DateTime.now();
  final base = DateTime(now.year, now.month, now.day);
  return [
    for (int i = 6; i >= 0; i--)
      (i == 0 ? todayMl : _mlForDay(prefs, base.subtract(Duration(days: i)))) ~/
          kGlassMl,
  ];
});

/// Millilitres of water for the last 7 days (for the hydration chart).
final weeklyWaterMlProvider = Provider<List<int>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final todayMl = ref.watch(waterMlProvider);
  final now = DateTime.now();
  final base = DateTime(now.year, now.month, now.day);
  return [
    for (int i = 6; i >= 0; i--)
      i == 0 ? todayMl : _mlForDay(prefs, base.subtract(Duration(days: i))),
  ];
});
