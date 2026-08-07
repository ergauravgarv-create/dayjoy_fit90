import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs_provider.dart';

/// Tracks the days the participant completed a mindfulness session (breathing
/// or meditation), persisted on-device. Drives the "mindful streak".
final mindfulnessProvider =
    NotifierProvider<MindfulnessController, Set<String>>(
        MindfulnessController.new);

class MindfulnessController extends Notifier<Set<String>> {
  static const String _key = 'mindful_days';

  @override
  Set<String> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      return (jsonDecode(raw) as List).map((e) => e as String).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Mark today as a completed mindfulness day.
  void markDoneToday() {
    final today = _dayKey(DateTime.now());
    if (state.contains(today)) return;
    state = {...state, today};
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state.toList()));
  }

  bool get doneToday => state.contains(_dayKey(DateTime.now()));

  int get totalSessions => state.length;

  /// Consecutive days ending today (or yesterday if today isn't done yet).
  int get streak {
    int s = 0;
    DateTime d = DateTime.now();
    if (!state.contains(_dayKey(d))) {
      d = d.subtract(const Duration(days: 1));
    }
    while (state.contains(_dayKey(d))) {
      s++;
      d = d.subtract(const Duration(days: 1));
    }
    return s;
  }
}

/// Whether a mindful session is already logged today.
final mindfulDoneTodayProvider = Provider<bool>((ref) {
  ref.watch(mindfulnessProvider);
  return ref.read(mindfulnessProvider.notifier).doneToday;
});

/// Current mindful streak (consecutive days).
final mindfulStreakProvider = Provider<int>((ref) {
  ref.watch(mindfulnessProvider);
  return ref.read(mindfulnessProvider.notifier).streak;
});
