import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs_provider.dart';

/// Millilitres in one glass.
const int kGlassMl = 250;

/// SharedPreferences key for a given day's water count, e.g. "water_2026-08-01".
String waterKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return 'water_${d.year}-$m-$day';
}

/// Today's water intake in glasses, persisted on-device per day (survives
/// restarts; each calendar day starts fresh).
final waterProvider = NotifierProvider<WaterController, int>(WaterController.new);

class WaterController extends Notifier<int> {
  String get _key => waterKey(DateTime.now());

  @override
  int build() => ref.watch(sharedPreferencesProvider).getInt(_key) ?? 0;

  void _persist() =>
      ref.read(sharedPreferencesProvider).setInt(_key, state);

  void add() {
    state = (state + 1).clamp(0, 30);
    _persist();
  }

  void remove() {
    state = (state - 1).clamp(0, 30);
    _persist();
  }
}

/// Glasses of water for the last 7 days (oldest → newest, today last). Today
/// comes from the live counter; earlier days are read from their stored keys.
final weeklyWaterProvider = Provider<List<int>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final today = ref.watch(waterProvider);
  final now = DateTime.now();
  final base = DateTime(now.year, now.month, now.day);
  return [
    for (int i = 6; i >= 0; i--)
      i == 0
          ? today
          : (prefs.getInt(waterKey(base.subtract(Duration(days: i)))) ?? 0),
  ];
});
