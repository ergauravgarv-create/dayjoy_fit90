import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'measurements_provider.dart';
import 'mindfulness_provider.dart';
import 'prefs_provider.dart';
import 'providers.dart';

String streakDayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _parseKey(String k) {
  final p = k.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// Freeze tokens + the days they've protected.
class FreezeState {
  const FreezeState({required this.tokens, required this.frozen});
  final int tokens;
  final Set<String> frozen;
}

final freezeStateProvider =
    NotifierProvider<FreezeController, FreezeState>(FreezeController.new);

class FreezeController extends Notifier<FreezeState> {
  static const String _key = 'streak_freeze';
  static const int _startingTokens = 2;

  @override
  FreezeState build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) {
      return const FreezeState(tokens: _startingTokens, frozen: {});
    }
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return FreezeState(
        tokens: (j['tokens'] as num?)?.toInt() ?? _startingTokens,
        frozen: ((j['frozen'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
      );
    } catch (_) {
      return const FreezeState(tokens: _startingTokens, frozen: {});
    }
  }

  /// Protect [day] (defaults to today) by spending a token. Returns false when
  /// there are no tokens left or the day is already protected.
  bool useFreeze([DateTime? day]) {
    if (state.tokens <= 0) return false;
    final key = streakDayKey(day ?? DateTime.now());
    if (state.frozen.contains(key)) return false;
    state = FreezeState(
        tokens: state.tokens - 1, frozen: {...state.frozen, key});
    _persist();
    return true;
  }

  void _persist() {
    ref.read(sharedPreferencesProvider).setString(
        _key,
        jsonEncode(
            {'tokens': state.tokens, 'frozen': state.frozen.toList()}));
  }
}

/// The set of "active" calendar days (yyyy-MM-dd). Honestly derived: the current
/// streak occupies the last N days ending today, unioned with real logged
/// activity (mindfulness, measurements) and any frozen days.
final activeDaysProvider = Provider<Set<String>>((ref) {
  final int streak = ref.watch(participantProvider)?.streak ?? 0;
  final now = DateTime.now();
  final days = <String>{};
  for (int i = 0; i < streak; i++) {
    days.add(streakDayKey(now.subtract(Duration(days: i))));
  }
  days.addAll(ref.watch(mindfulnessProvider));
  for (final m in ref.watch(measurementsProvider)) {
    days.add(streakDayKey(m.date));
  }
  days.addAll(ref.watch(freezeStateProvider).frozen);
  return days;
});

/// Longest run of consecutive active days.
final longestStreakProvider = Provider<int>((ref) {
  final days = ref.watch(activeDaysProvider);
  if (days.isEmpty) return 0;
  final dates = days.map(_parseKey).toList()..sort();
  int best = 1;
  int run = 1;
  for (int i = 1; i < dates.length; i++) {
    final diff = dates[i].difference(dates[i - 1]).inDays;
    if (diff == 1) {
      run++;
      if (run > best) best = run;
    } else if (diff > 1) {
      run = 1;
    }
  }
  return best;
});
