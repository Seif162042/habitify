import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final int points;
  final int totalHabitsCompleted;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.points,
    required this.totalHabitsCompleted,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      points: data['points'] ?? 0,
      totalHabitsCompleted: data['totalHabitsCompleted'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'points': points,
      'totalHabitsCompleted': totalHabitsCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
