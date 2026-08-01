import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The daily habits a participant can be reminded about.
enum ReminderKind { morningYoga, breakfast, lunch, dinner, water, steps }

extension ReminderKindX on ReminderKind {
  String get label => switch (this) {
        ReminderKind.morningYoga => 'Morning Yoga',
        ReminderKind.breakfast => 'Breakfast',
        ReminderKind.lunch => 'Lunch',
        ReminderKind.dinner => 'Dinner',
        ReminderKind.water => 'Drink Water',
        ReminderKind.steps => 'Evening Walk / Steps',
      };

  IconData get icon => switch (this) {
        ReminderKind.morningYoga => Icons.self_improvement_rounded,
        ReminderKind.breakfast => Icons.free_breakfast_rounded,
        ReminderKind.lunch => Icons.lunch_dining_rounded,
        ReminderKind.dinner => Icons.dinner_dining_rounded,
        ReminderKind.water => Icons.water_drop_rounded,
        ReminderKind.steps => Icons.directions_walk_rounded,
      };

  /// Notification body shown when the reminder fires.
  String get message => switch (this) {
        ReminderKind.morningYoga =>
          'Start your day with your yoga session. Capture your proof! 🧘',
        ReminderKind.breakfast =>
          'Time for a healthy breakfast — log it in your diary. 🍳',
        ReminderKind.lunch => 'Lunch time! Keep it balanced and logged. 🥗',
        ReminderKind.dinner =>
          'Dinner reminder — eat light and log your meal. 🍲',
        ReminderKind.water =>
          'Stay hydrated — have a glass of water and tap +1. 💧',
        ReminderKind.steps =>
          'Time to move! Get those 10,000 steps in. 🚶',
      };

  TimeOfDay get defaultTime => switch (this) {
        ReminderKind.morningYoga => const TimeOfDay(hour: 6, minute: 30),
        ReminderKind.breakfast => const TimeOfDay(hour: 8, minute: 30),
        ReminderKind.lunch => const TimeOfDay(hour: 13, minute: 0),
        ReminderKind.dinner => const TimeOfDay(hour: 20, minute: 0),
        ReminderKind.water => const TimeOfDay(hour: 11, minute: 0),
        ReminderKind.steps => const TimeOfDay(hour: 18, minute: 0),
      };

  /// Stable notification id per reminder.
  int get notificationId => 1000 + index;
}

/// A single configurable reminder.
class Reminder {
  const Reminder({
    required this.kind,
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final ReminderKind kind;
  final bool enabled;
  final int hour;
  final int minute;

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  Reminder copyWith({bool? enabled, int? hour, int? minute}) => Reminder(
        kind: kind,
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.index,
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        kind: ReminderKind.values[(j['kind'] as num).toInt()],
        enabled: j['enabled'] as bool? ?? false,
        hour: (j['hour'] as num).toInt(),
        minute: (j['minute'] as num).toInt(),
      );

  factory Reminder.defaultsFor(ReminderKind kind) => Reminder(
        kind: kind,
        enabled: false,
        hour: kind.defaultTime.hour,
        minute: kind.defaultTime.minute,
      );
}

const String _prefsKey = 'reminders_v1';

/// Load saved reminders (or defaults) from storage.
List<Reminder> loadReminders(SharedPreferences prefs) {
  final raw = prefs.getString(_prefsKey);
  final defaults = [
    for (final k in ReminderKind.values) Reminder.defaultsFor(k),
  ];
  if (raw == null || raw.isEmpty) return defaults;
  try {
    final list = (jsonDecode(raw) as List)
        .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
        .toList();
    // Ensure every kind is present (in case new kinds were added later).
    return [
      for (final k in ReminderKind.values)
        list.firstWhere((r) => r.kind == k,
            orElse: () => Reminder.defaultsFor(k)),
    ];
  } catch (_) {
    return defaults;
  }
}

Future<void> saveReminders(
    SharedPreferences prefs, List<Reminder> reminders) {
  return prefs.setString(
      _prefsKey, jsonEncode(reminders.map((r) => r.toJson()).toList()));
}
