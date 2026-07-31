import '../models/leaderboard_entry.dart';

/// Reads the server-built leaderboards (`leaderboards/{period}`).
/// Periods: overall, highestStreak, maxWeightLost, mostConsistent,
/// daily, weekly, monthly.
abstract interface class LeaderboardRepository {
  Stream<List<LeaderboardEntry>> watch(String period);
  List<LeaderboardEntry>? currentSnapshot(String period);
}
