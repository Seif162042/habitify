class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int points;
  final int totalHabitsCompleted;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.points,
    required this.totalHabitsCompleted,
  });
}
