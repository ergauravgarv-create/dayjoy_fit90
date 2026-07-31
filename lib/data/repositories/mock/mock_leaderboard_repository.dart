import '../../mock/mock_data.dart';
import '../../models/leaderboard_entry.dart';
import '../leaderboard_repository.dart';

class MockLeaderboardRepository implements LeaderboardRepository {
  @override
  Stream<List<LeaderboardEntry>> watch(String period) =>
      Stream<List<LeaderboardEntry>>.value(MockData.leaderboard);

  @override
  List<LeaderboardEntry>? currentSnapshot(String period) => MockData.leaderboard;
}
