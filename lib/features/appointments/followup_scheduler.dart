import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/appointment.dart';
import '../../state/reminders_provider.dart';

/// Stable, collision-free notification id for an appointment's follow-up
/// reminder. Daily habit reminders live at 1000+, so we sit at 900000+.
int followUpNotifId(String apptId) {
  int h = 0;
  for (final c in apptId.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return 900000 + (h % 90000);
}

/// Keeps the phone's local notifications in sync with the participant's
/// recommended follow-up dates. Schedules a one-off reminder the morning before
/// each upcoming follow-up (so it fires even when the app is closed), and
/// cancels reminders that no longer apply (cancelled, no date, or already
/// rebooked with the same provider).
Future<void> syncFollowUpReminders(
  WidgetRef ref,
  List<Appointment> appts,
) async {
  final service = ref.read(notificationServiceProvider);
  final now = DateTime.now();

  final toSchedule = <Appointment>[];
  for (final a in appts) {
    final fu = a.followUpAt;
    final bool wanted = fu != null &&
        a.status != AppointmentStatus.cancelled &&
        // Still relevant if within a day-old of the date or in the future.
        fu.isAfter(now.subtract(const Duration(days: 1))) &&
        !_alreadyRebooked(appts, a);
    if (wanted) {
      toSchedule.add(a);
    } else {
      await service.cancel(followUpNotifId(a.id));
    }
  }

  if (toSchedule.isEmpty) return;

  // Only prompt for permission when there's actually something to schedule.
  await service.requestPermission();

  for (final a in toSchedule) {
    final fu = a.followUpAt!;
    // The morning before at 9:00; if that's already past, the morning of.
    DateTime when = DateTime(fu.year, fu.month, fu.day, 9)
        .subtract(const Duration(days: 1));
    if (when.isBefore(now)) {
      when = DateTime(fu.year, fu.month, fu.day, 9);
    }
    final provider =
        a.providerRole == ProviderKind.doctor ? 'doctor' : 'trainer';
    await service.scheduleOnceAt(
      id: followUpNotifId(a.id),
      title: 'Follow-up reminder',
      body: 'Time to book your follow-up with your $provider. '
          'Open Dayjoy Fit90 → My consultations.',
      when: when,
    );
  }
}

/// True if the participant already has an upcoming (requested/confirmed) booking
/// with the same provider around/after the follow-up window — no need to nudge.
bool _alreadyRebooked(List<Appointment> appts, Appointment a) {
  final fu = a.followUpAt;
  if (fu == null) return false;
  final from = fu.subtract(const Duration(days: 2));
  return appts.any((o) =>
      o.id != a.id &&
      o.providerRole == a.providerRole &&
      (o.status == AppointmentStatus.requested ||
          o.status == AppointmentStatus.confirmed) &&
      o.scheduledAt != null &&
      o.scheduledAt!.isAfter(from));
}
