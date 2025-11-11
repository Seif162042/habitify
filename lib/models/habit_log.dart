class HabitLog {
  final String id;
  final String habitId;
  final String userId;
  final DateTime completedAt;
  final int pointsEarned;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    this.pointsEarned = 10,
  });

  factory HabitLog.fromMap(Map<String, dynamic> map, String id) {
    return HabitLog(
      id: id,
      habitId: map['habitId'] ?? '',
      userId: map['userId'] ?? '',
      completedAt: map['completedAt']?.toDate() ?? DateTime.now(),
      pointsEarned: map['pointsEarned'] ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'userId': userId,
      'completedAt': completedAt,
      'pointsEarned': pointsEarned,
    };
  }
}
