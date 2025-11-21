import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String userId;
  final String name;
  final String description;
  final int streak;
  final Timestamp? lastCompletedDate;
  final DateTime createdAt;
  final int reminderHour;
  final int reminderMinute;

  Habit({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.streak,
    this.lastCompletedDate,
    required this.createdAt,
    this.reminderHour = 9,
    this.reminderMinute = 0,
  });

  factory Habit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      streak: data['streak'] ?? 0,
      lastCompletedDate: data['lastCompletedDate'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reminderHour: data['reminderHour'] ?? 9,
      reminderMinute: data['reminderMinute'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'streak': streak,
      'lastCompletedDate': lastCompletedDate,
      'createdAt': Timestamp.fromDate(createdAt),
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
    };
  }
}
