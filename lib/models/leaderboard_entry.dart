/// A single entry on the leaderboard (rank, user id, display name, balance).
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.uid,
    required this.displayName,
    required this.balanceBtc,
  });

  final int rank;
  final String uid;
  final String displayName;
  final double balanceBtc;
}
