/// A row on the leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.city,
    required this.points,
    required this.streak,
    required this.weightLostKg,
    this.weeklyPoints = 0,
    this.previousRank = 0,
    this.photoUrl,
    this.isCurrentUser = false,
  });

  final int rank;
  final String name;
  final String city;
  final int points;

  /// Points earned in the current week (drives the "This week" ranking).
  final int weeklyPoints;

  /// The member's rank last week (0 = new / unknown); drives movement arrows.
  final int previousRank;

  final int streak;
  final double weightLostKg;
  final String? photoUrl;
  final bool isCurrentUser;
}
