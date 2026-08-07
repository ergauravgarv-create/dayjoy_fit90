import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_notification.dart';
import 'achievements_provider.dart';
import 'community_provider.dart';
import 'prefs_provider.dart';

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

  final items = <AppNotification>[];

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
