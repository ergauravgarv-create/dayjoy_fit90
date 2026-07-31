import '../models/badge.dart';

/// Reads the participant's earned badges.
abstract interface class BadgeRepository {
  Stream<List<AwardedBadge>> watch(String uid);
}
