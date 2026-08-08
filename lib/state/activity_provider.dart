import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_notification.dart';
import '../data/models/appointment.dart';
import 'achievements_provider.dart';
import 'appointments_provider.dart';
import 'community_provider.dart';
import 'prefs_provider.dart';
import 'subscription_provider.dart';

/// Ids of local activity items the user has read, persisted on-device.
final activityReadProvider =
    NotifierProvider<ActivityReadController, Set<String>>(
        ActivityReadController.new);

class ActivityReadController extends Notifier<Set<String>> {
  static const String _key = 'activity_read';

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

  void markRead(String id) {
    if (state.contains(id)) return;
    state = {...state, id};
    _persist();
  }

  void markAll(Iterable<String> ids) {
    state = {...state, ...ids};
    _persist();
  }

  void _persist() {
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state.toList()));
  }
}

/// In-app activity generated from real local state: badges unlocked and
/// challenges claimed. Merged with the server notifications in the inbox.
final localActivityProvider = Provider<List<AppNotification>>((ref) {
  final read = ref.watch(activityReadProvider);
  final badges = ref.watch(earnedBadgesProvider); // id -> awardedAt
  final claimed = ref.watch(claimedChallengesProvider); // id -> claimedAt
  final myAppts =
      ref.watch(myAppointmentsProvider).valueOrNull ?? const <Appointment>[];

  final items = <AppNotification>[];

  // A confirmed consultation → "your call is confirmed, tap to join" alert.
  for (final a in myAppts) {
    if (a.status != AppointmentStatus.confirmed) continue;
    final provider = a.providerRole == ProviderKind.doctor ? 'doctor' : 'trainer';
    final when = a.scheduledAt;
    final whenStr = when == null
        ? ''
        : ' on ${_dayName(when.weekday)} ${when.day} at ${_hhmm(when)}';
    final stamp =
        (a.confirmedAt ?? a.scheduledAt ?? a.requestedAt).millisecondsSinceEpoch;
    final id = 'appt_confirmed_${a.id}_$stamp';
    items.add(AppNotification(
      id: id,
      title: 'Consultation confirmed',
      body: 'Your ${a.mode.label.toLowerCase()} with your $provider is '
          'confirmed$whenStr. Open “My consultations” to join.',
      type: 'appointment',
      read: read.contains(id),
      createdAt: a.confirmedAt ?? a.scheduledAt ?? a.requestedAt,
    ));
  }

  // A note/prescription shared by the provider → "notes are ready" alert.
  for (final a in myAppts) {
    final note = a.providerNote;
    if (note == null || note.isEmpty) continue;
    final provider = a.providerRole == ProviderKind.doctor ? 'doctor' : 'trainer';
    final fu = a.followUpAt;
    final followUpStr = fu == null
        ? ''
        : ' Follow-up suggested on ${_dayName(fu.weekday)} ${fu.day}.';
    final id =
        'appt_note_${a.id}_${(a.noteAt ?? a.requestedAt).millisecondsSinceEpoch}';
    items.add(AppNotification(
      id: id,
      title: 'Consultation notes shared',
      body: 'Your $provider shared notes for your ${a.type} consultation.'
          '$followUpStr Open “My consultations” to read them.',
      type: 'consultNote',
      read: read.contains(id),
      createdAt: a.noteAt ?? a.confirmedAt ?? a.requestedAt,
    ));
  }

  // Follow-up reminder: nudge from 2 days before the recommended date until a
  // week after — unless they've already booked another visit with that provider.
  final nowDt = DateTime.now();
  for (final a in myAppts) {
    final fu = a.followUpAt;
    if (fu == null) continue;
    final remindFrom = fu.subtract(const Duration(days: 2));
    final remindUntil = fu.add(const Duration(days: 7));
    if (nowDt.isBefore(remindFrom) || nowDt.isAfter(remindUntil)) continue;

    final hasUpcoming = myAppts.any((o) =>
        o.id != a.id &&
        o.providerRole == a.providerRole &&
        (o.status == AppointmentStatus.requested ||
            o.status == AppointmentStatus.confirmed) &&
        o.scheduledAt != null &&
        o.scheduledAt!.isAfter(remindFrom));
    if (hasUpcoming) continue;

    final provider = a.providerRole == ProviderKind.doctor ? 'doctor' : 'trainer';
    final bool overdue = nowDt.isAfter(fu);
    final dateStr = '${_dayName(fu.weekday)} ${fu.day}';
    final id = 'appt_followup_${a.id}_${fu.millisecondsSinceEpoch}';
    items.add(AppNotification(
      id: id,
      title: overdue ? 'Follow-up due' : 'Follow-up reminder',
      body: overdue
          ? 'Your follow-up with your $provider ($dateStr) is due — tap to book it.'
          : 'Your $provider recommended a follow-up on $dateStr. Tap to book it now.',
      type: 'followUp',
      read: read.contains(id),
      createdAt: remindFrom,
    ));
  }

  // Subscription expiry / renewal reminder.
  final sub = ref.watch(subscriptionProvider);
  if (sub != null) {
    final planName = sub.plan?.title ?? 'Fit90';
    if (sub.isActive) {
      final int days = sub.expiresAt.difference(nowDt).inDays;
      if (days <= 7) {
        final id = 'sub_expiry_${sub.expiresAt.millisecondsSinceEpoch}';
        final left = days <= 0
            ? 'today'
            : 'in $days day${days == 1 ? '' : 's'}';
        items.add(AppNotification(
          id: id,
          title: 'Your plan is expiring',
          body: 'Your $planName plan expires $left. Renew to keep premium access.',
          type: 'subscription',
          read: read.contains(id),
          createdAt: sub.expiresAt.subtract(const Duration(days: 7)),
        ));
      }
    } else if (nowDt.difference(sub.expiresAt).inDays <= 14) {
      final id = 'sub_expired_${sub.expiresAt.millisecondsSinceEpoch}';
      items.add(AppNotification(
        id: id,
        title: 'Your plan has expired',
        body: 'Your $planName plan has expired. Renew to unlock premium again.',
        type: 'subscription',
        read: read.contains(id),
        createdAt: sub.expiresAt,
      ));
    }
  }

  for (final e in badges.entries) {
    final matches = kAchievements.where((d) => d.id == e.key);
    if (matches.isEmpty) continue;
    final id = 'badge_${e.key}';
    items.add(AppNotification(
      id: id,
      title: 'Badge unlocked',
      body: '${matches.first.title} — ${matches.first.description}',
      type: 'badge',
      read: read.contains(id),
      createdAt: e.value,
    ));
  }

  for (final e in claimed.entries) {
    final matches = kChallenges.where((c) => c.id == e.key);
    if (matches.isEmpty) continue;
    final c = matches.first;
    final id = 'challenge_${e.key}';
    items.add(AppNotification(
      id: id,
      title: 'Challenge complete',
      body: '${c.title} · +${c.bonusPoints} bonus points',
      type: 'challenge',
      read: read.contains(id),
      createdAt: e.value,
    ));
  }

  items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items;
});

/// Count of unread local activity items (feeds the bell badge).
final localUnreadProvider = Provider<int>(
    (ref) => ref.watch(localActivityProvider).where((n) => !n.read).length);

const List<String> _days = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun' //
];

String _dayName(int weekday) => _days[(weekday - 1) % 7];

String _hhmm(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}
