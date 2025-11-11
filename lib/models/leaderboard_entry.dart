class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int totalPoints;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.totalPoints,
    required this.rank,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, int rank) {
    return LeaderboardEntry(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? 'Anonymous',
      totalPoints: map['totalPoints'] ?? 0,
      rank: rank,
    );
  }
}
