import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit_model.dart';
import '../models/habit_log.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<HabitModel>> getUserHabits(String userId) {
    return _firestore
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HabitModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addHabit(HabitModel habit) async {
    await _firestore.collection('habits').add(habit.toMap());
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _firestore.collection('habits').doc(habit.id).update(habit.toMap());
  }

  Future<void> deleteHabit(String habitId) async {
    await _firestore.collection('habits').doc(habitId).delete();
  }

  Future<void> completeHabit(String habitId, String userId) async {
    final habitDoc = await _firestore.collection('habits').doc(habitId).get();
    if (!habitDoc.exists) return;

    final habit = HabitModel.fromMap(habitDoc.data()!, habitDoc.id);
    final now = DateTime.now();
    final lastCompleted = habit.lastCompletedDate;

    int newStreak = habit.streak;
    if (lastCompleted == null) {
      newStreak = 1;
    } else {
      final difference = now.difference(lastCompleted).inDays;
      if (difference == 1) {
        newStreak = habit.streak + 1;
      } else if (difference > 1) {
        newStreak = 1;
      }
    }

    // Update habit
    await _firestore.collection('habits').doc(habitId).update({
      'streak': newStreak,
      'lastCompletedDate': now,
    });

    // Log completion
    await _firestore.collection('habitLogs').add(
      HabitLog(
        id: '',
        habitId: habitId,
        userId: userId,
        completedAt: now,
        pointsEarned: 10,
      ).toMap(),
    );

    // Update user points
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final currentPoints = userDoc.data()?['totalPoints'] ?? 0;
      await _firestore.collection('users').doc(userId).update({
        'totalPoints': currentPoints + 10,
      });
    }
  }
}
