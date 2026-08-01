import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notifications/notification_service.dart';
import '../services/notifications/reminder.dart';
import 'prefs_provider.dart';

/// The platform notification scheduler (real on mobile, no-op on web).
final notificationServiceProvider = Provider<NotificationService>(
    (ref) => createNotificationService());

/// The user's configured reminders, persisted on-device. Toggling or retiming a
/// reminder immediately (re)schedules or cancels its OS notification.
final remindersProvider =
    NotifierProvider<RemindersController, List<Reminder>>(
        RemindersController.new);

class RemindersController extends Notifier<List<Reminder>> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
  NotificationService get _service => ref.read(notificationServiceProvider);

  @override
  List<Reminder> build() => loadReminders(_prefs);

  Reminder _byKind(ReminderKind k) => state.firstWhere((r) => r.kind == k);

  Future<void> _replace(Reminder updated) async {
    state = [
      for (final r in state) if (r.kind == updated.kind) updated else r,
    ];
    await saveReminders(_prefs, state);
    await _apply(updated);
  }

  Future<void> _apply(Reminder r) async {
    if (r.enabled) {
      await _service.scheduleDaily(
        id: r.kind.notificationId,
        title: r.kind.label,
        body: r.kind.message,
        hour: r.hour,
        minute: r.minute,
      );
    } else {
      await _service.cancel(r.kind.notificationId);
    }
  }

  Future<void> setEnabled(ReminderKind kind, bool enabled) async {
    if (enabled) await _service.requestPermission();
    await _replace(_byKind(kind).copyWith(enabled: enabled));
  }

  Future<void> setTime(ReminderKind kind, TimeOfDay time) async {
    await _replace(
        _byKind(kind).copyWith(hour: time.hour, minute: time.minute));
  }

  /// Re-schedule every enabled reminder (e.g. on app launch).
  Future<void> rescheduleAll() async {
    for (final r in state) {
      await _apply(r);
    }
  }
}

/// Called once at startup so enabled reminders survive app restarts. Reads
/// straight from prefs and schedules via the platform service; safe on web
/// (the service is a no-op there) and wrapped so it never blocks launch.
Future<void> bootstrapReminders(SharedPreferences prefs) async {
  try {
    final service = createNotificationService();
    await service.init();
    for (final r in loadReminders(prefs)) {
      if (r.enabled) {
        await service.scheduleDaily(
          id: r.kind.notificationId,
          title: r.kind.label,
          body: r.kind.message,
          hour: r.hour,
          minute: r.minute,
        );
      }
    }
  } catch (_) {
    // Never let reminder setup interfere with app launch.
  }
}
