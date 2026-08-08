import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/appointment.dart';
import 'providers.dart';
import 'repository_providers.dart';

/// The signed-in participant's own consultations (doctor + trainer), newest
/// first. Reactive: reflects new bookings and staff confirmations live.
final myAppointmentsProvider =
    StreamProvider.autoDispose<List<Appointment>>((ref) {
  final uid = ref.watch(authUidProvider) ?? 'demo-user';
  return ref
      .watch(staffRepositoryProvider)
      .watchParticipantAppointments(uid)
      .map((list) {
    final sorted = [...list];
    sorted.sort((a, b) {
      final da = a.scheduledAt ?? a.requestedAt;
      final db = b.scheduledAt ?? b.requestedAt;
      return db.compareTo(da);
    });
    return sorted;
  });
});

// ===== No-show booking restriction (§5 fair-use safeguard) =================

/// Repeated no-shows temporarily pause advance booking.
const int kNoShowWindowDays = 30; // look-back window
const int kNoShowThreshold = 2; // no-shows that trigger a restriction
const int kNoShowCooldownDays = 7; // pause length after the latest no-show

class BookingRestriction {
  const BookingRestriction({
    required this.restricted,
    required this.recentNoShows,
    this.until,
  });

  final bool restricted;
  final int recentNoShows;
  final DateTime? until;
}

/// Whether the participant's advance booking is temporarily restricted because
/// of repeated no-shows in the recent window.
final bookingRestrictionProvider =
    Provider.autoDispose<BookingRestriction>((ref) {
  final appts = ref.watch(myAppointmentsProvider).valueOrNull ?? const [];
  final now = DateTime.now();
  final windowStart = now.subtract(const Duration(days: kNoShowWindowDays));

  final noShowTimes = <DateTime>[];
  for (final a in appts) {
    if (a.status != AppointmentStatus.noShow) continue;
    final when = a.scheduledAt ?? a.requestedAt;
    if (when.isAfter(windowStart)) noShowTimes.add(when);
  }

  if (noShowTimes.length < kNoShowThreshold) {
    return BookingRestriction(
        restricted: false, recentNoShows: noShowTimes.length);
  }

  final latest = noShowTimes.reduce((a, b) => a.isAfter(b) ? a : b);
  final until = latest.add(const Duration(days: kNoShowCooldownDays));
  return BookingRestriction(
    restricted: now.isBefore(until),
    recentNoShows: noShowTimes.length,
    until: now.isBefore(until) ? until : null,
  );
});
