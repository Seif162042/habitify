import 'package:cloud_firestore/cloud_firestore.dart';

class HabitLog {
  final String habitId;
  final String userId;
  final DateTime completedAt;
  final int streakAtCompletion;

  HabitLog({
    required this.habitId,
    required this.userId,
    required this.completedAt,
    required this.streakAtCompletion,
  });

  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'userId': userId,
      'completedAt': Timestamp.fromDate(completedAt),
      'streakAtCompletion': streakAtCompletion,
    };
  }
}
