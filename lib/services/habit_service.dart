import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit_model.dart';
import '../models/habit_log.dart';
import 'notification_service.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Habit>> getUserHabits(String userId) {
    return _firestore
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final habits =
          snapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList();
      // Sort by createdAt on client side to avoid needing Firebase composite index
      habits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return habits;
    });
  }

  Future<void> addHabit(Habit habit) async {
    final docRef = await _firestore.collection('habits').add(habit.toMap());

    // Schedule daily reminder notification with custom time
    await NotificationService.scheduleHabitReminder(
      docRef.id.hashCode,
      habit.name,
      habit.reminderHour,
      habit.reminderMinute,
    );
  }

  Future<void> logHabitCompletion(String habitId, String userId) async {
    final habitRef = _firestore.collection('habits').doc(habitId);
    final habitDoc = await habitRef.get();

    if (!habitDoc.exists) return;

    final habit = Habit.fromFirestore(habitDoc);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool shouldUpdateStreak = true;
    int newStreak = habit.streak;

    if (habit.lastCompletedDate != null) {
      final lastCompleted = habit.lastCompletedDate!.toDate();
      final lastCompletedDay =
          DateTime(lastCompleted.year, lastCompleted.month, lastCompleted.day);

      if (lastCompletedDay.isAtSameMomentAs(today)) {
        return;
      }

      final daysDifference = today.difference(lastCompletedDay).inDays;

      if (daysDifference == 1) {
        newStreak = habit.streak + 1;
      } else if (daysDifference > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    await habitRef.update({
      'streak': newStreak,
      'lastCompletedDate': Timestamp.fromDate(now),
    });

    await _firestore.collection('habitLogs').add(HabitLog(
          habitId: habitId,
          userId: userId,
          completedAt: now,
          streakAtCompletion: newStreak,
        ).toMap());

    // IMPROVED POINTS SYSTEM: Reward longer streaks
    int pointsToAdd = 10; // Base points
    
    if (newStreak >= 100) {
      pointsToAdd = 50; // 💯 Legendary streak (100+ days)
    } else if (newStreak >= 30) {
      pointsToAdd = 30; // 🏆 Monthly streak (30-99 days)
    } else if (newStreak >= 7) {
      pointsToAdd = 20; // 🎉 Weekly streak (7-29 days)
    } else if (newStreak >= 3) {
      pointsToAdd = 15; // ✨ 3-day streak (3-6 days)
    }

    final userRef = _firestore.collection('users').doc(userId);
    await userRef.update({
      'points': FieldValue.increment(pointsToAdd),
      'totalHabitsCompleted': FieldValue.increment(1),
    });

    print('✅ Added $pointsToAdd points for ${habit.name} (streak: $newStreak)');

    // Show completion notification
    await NotificationService.showHabitCompletedNotification(
      habitId.hashCode,
      habit.name,
    );

    // Check for streak milestones and celebrate
    await NotificationService.checkAndCelebrateStreak(
      habitId.hashCode + 1000,
      habit.name,
      newStreak,
    );
  }

  Future<void> checkIncompleteHabitsAndNotify(String userId) async {
    final habits = await _firestore
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int incompleteCount = 0;

    for (var doc in habits.docs) {
      final habit = Habit.fromFirestore(doc);

      bool completedToday = false;
      if (habit.lastCompletedDate != null) {
        final lastCompleted = habit.lastCompletedDate!.toDate();
        final lastCompletedDay = DateTime(
            lastCompleted.year, lastCompleted.month, lastCompleted.day);
        completedToday = lastCompletedDay.isAtSameMomentAs(today);
      }

      if (!completedToday) {
        incompleteCount++;
      }
    }

    // Schedule both afternoon and evening reminders
    await NotificationService.scheduleAfternoonReminder(incompleteCount);
    await NotificationService.scheduleEveningReminder(incompleteCount);
  }


  // Check and reset streaks for habits that haven't been completed
  Future<void> checkAndResetStreaks(String userId) async {
    try {
      final habits = await _firestore
          .collection('habits')
          .where('userId', isEqualTo: userId)
          .get();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var doc in habits.docs) {
        final habit = Habit.fromFirestore(doc);
        
        if (habit.lastCompletedDate != null) {
          final lastCompleted = habit.lastCompletedDate!.toDate();
          final lastCompletedDay = DateTime(
            lastCompleted.year,
            lastCompleted.month,
            lastCompleted.day,
          );

          final daysDifference = today.difference(lastCompletedDay).inDays;

          // If more than 1 day has passed, reset streak to 0
          if (daysDifference > 1) {
            await doc.reference.update({'streak': 0});
            print('🔄 Reset streak for habit: ${habit.name}');
          }
        }
      }
    } catch (e) {
      print('Error checking streaks: $e');
    }
  }

  // Delete a habit
  Future<void> deleteHabit(String habitId) async {
    try {
      // Cancel scheduled notifications for this habit
      await NotificationService.cancelHabitReminder(habitId.hashCode);

      // Delete the habit document
      await _firestore.collection('habits').doc(habitId).delete();

      // Delete associated habit logs
      final logs = await _firestore
          .collection('habitLogs')
          .where('habitId', isEqualTo: habitId)
          .get();

      for (var log in logs.docs) {
        await log.reference.delete();
      }
    } catch (e) {
      print('Error deleting habit: $e');
      rethrow;
    }
  }
}
