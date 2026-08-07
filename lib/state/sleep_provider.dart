import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs_provider.dart';

/// One night's logged sleep. [dateMillis] is the morning (wake) date at
/// midnight, so there's one entry per day. Bed/wake are minutes-of-day.
class SleepEntry {
  const SleepEntry({
    required this.dateMillis,
    required this.bedMinute,
    required this.wakeMinute,
    required this.quality,
  });

  final int dateMillis;
  final int bedMinute; // minutes from midnight (e.g. 22:30 = 1350)
  final int wakeMinute;
  final int quality; // 1..5

  int get durationMinutes {
    int d = wakeMinute - bedMinute;
    if (d <= 0) d += 1440; // crossed midnight
    return d;
  }

  double get hours => durationMinutes / 60.0;

  Map<String, dynamic> toJson() =>
      {'date': dateMillis, 'bed': bedMinute, 'wake': wakeMinute, 'q': quality};

  factory SleepEntry.fromJson(Map<String, dynamic> j) => SleepEntry(
        dateMillis: (j['date'] as num).toInt(),
        bedMinute: (j['bed'] as num).toInt(),
        wakeMinute: (j['wake'] as num).toInt(),
        quality: (j['q'] as num?)?.toInt() ?? 3,
      );
}

final sleepLogProvider =
    NotifierProvider<SleepLogController, List<SleepEntry>>(
        SleepLogController.new);

class SleepLogController extends Notifier<List<SleepEntry>> {
  static const String _key = 'sleep_log';

  @override
  List<SleepEntry> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => SleepEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.dateMillis.compareTo(b.dateMillis));
    } catch (_) {
      return const [];
    }
  }

  /// Log (or replace) the entry for [dateMillis]'s day.
  void log({
    required int dateMillis,
    required int bedMinute,
    required int wakeMinute,
    required int quality,
  }) {
    final next = state.where((e) => e.dateMillis != dateMillis).toList()
      ..add(SleepEntry(
          dateMillis: dateMillis,
          bedMinute: bedMinute,
          wakeMinute: wakeMinute,
          quality: quality))
      ..sort((a, b) => a.dateMillis.compareTo(b.dateMillis));
    state = next;
    _persist();
  }

  void _persist() {
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
}

/// Personal nightly sleep goal in hours (default 8), persisted.
final sleepGoalProvider =
    NotifierProvider<SleepGoalController, int>(SleepGoalController.new);

class SleepGoalController extends Notifier<int> {
  static const String _key = 'sleep_goal_hours';

  @override
  int build() => ref.watch(sharedPreferencesProvider).getInt(_key) ?? 8;

  void setGoal(int hours) {
    state = hours.clamp(5, 12).toInt();
    ref.read(sharedPreferencesProvider).setInt(_key, state);
  }
}

/// Hours slept for the last 7 days (oldest → newest, today last; 0 if none).
final weeklySleepHoursProvider = Provider<List<double>>((ref) {
  final log = ref.watch(sleepLogProvider);
  final now = DateTime.now();
  final base = DateTime(now.year, now.month, now.day);
  double forDay(DateTime d) {
    final key = DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
    final match = log.where((e) => e.dateMillis == key);
    return match.isEmpty ? 0 : match.first.hours;
  }

  return [for (int i = 6; i >= 0; i--) forDay(base.subtract(Duration(days: i)))];
});

/// Average hours across all logged nights (0 if none).
final avgSleepHoursProvider = Provider<double>((ref) {
  final log = ref.watch(sleepLogProvider);
  if (log.isEmpty) return 0;
  return log.fold<double>(0, (s, e) => s + e.hours) / log.length;
});
