import '../../mock/mock_data.dart';
import '../../models/badge.dart';
import '../badge_repository.dart';

/// Derives earned badges from the seeded participant's streak & day so the
/// gallery shows a realistic mix of earned/locked in the demo.
class MockBadgeRepository implements BadgeRepository {
  @override
  Stream<List<AwardedBadge>> watch(String uid) {
    final p = MockData.participant;
    final now = DateTime.now();
    final earned = <AwardedBadge>[];

    void add(String id, String label, bool cond) {
      if (cond) earned.add(AwardedBadge(id: id, label: label, awardedAt: now));
    }

    add('streak7', '7 Day Streak', p.streak >= 7);
    add('streak15', '15 Day Streak', p.streak >= 15);
    add('streak30', '30 Day Streak', p.streak >= 30);
    add('streak60', '60 Day Streak', p.streak >= 60);
    add('streak90', '90 Day Champion', p.streak >= 90);
    add('perfectWeek', 'Perfect Week', p.currentDay >= 7);

    return Stream<List<AwardedBadge>>.value(earned);
  }
}
