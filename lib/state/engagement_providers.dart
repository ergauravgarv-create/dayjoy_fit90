import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_notification.dart';
import '../data/models/badge.dart';
import 'providers.dart';
import 'repository_providers.dart';

/// Earned badges for the signed-in participant.
final badgesProvider = StreamProvider.autoDispose<List<AwardedBadge>>((ref) {
  final uid = ref.watch(authUidProvider) ?? 'demo-user';
  return ref.watch(badgeRepositoryProvider).watch(uid);
});

/// Notification inbox for the signed-in participant.
final notificationsProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final uid = ref.watch(authUidProvider) ?? 'demo-user';
  return ref.watch(notificationRepositoryProvider).watch(uid);
});

/// Unread notification count (drives the bell badge).
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  return ref
          .watch(notificationsProvider)
          .valueOrNull
          ?.where((n) => !n.read)
          .length ??
      0;
});
