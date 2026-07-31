/// A row on the leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.city,
    required this.points,
    required this.streak,
    required this.weightLostKg,
    this.photoUrl,
    this.isCurrentUser = false,
  });

  final int rank;
  final String name;
  final String city;
  final int points;
  final int streak;
  final double weightLostKg;
  final String? photoUrl;
  final bool isCurrentUser;
}
