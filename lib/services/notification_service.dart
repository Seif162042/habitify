import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    await _createNotificationChannels();
  }

  static Future<void> _createNotificationChannels() async {
    const habitReminders = AndroidNotificationChannel(
      'habit_reminders',
      'Habit Reminders',
      description: 'Daily reminders for your habits',
      importance: Importance.high,
    );

    const celebrations = AndroidNotificationChannel(
      'celebrations',
      'Celebrations',
      description: 'Streak milestones and achievements',
      importance: Importance.high,
    );

    const habitCompleted = AndroidNotificationChannel(
      'habit_completed',
      'Habit Completed',
      description: 'Confirmation when you complete a habit',
      importance: Importance.defaultImportance,
    );

    const eveningReminders = AndroidNotificationChannel(
      'evening_reminders',
      'Evening Reminders',
      description: 'End of day check-ins',
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(habitReminders);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(celebrations);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(habitCompleted);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(eveningReminders);
  }

  static Future<void> scheduleHabitReminder(
    int id,
    String habitName,
    int hour,
    int minute,
  ) async {
    await _notifications.zonedSchedule(
      id,
      '⏰ Time for: $habitName',
      _getMotivationalMessage(),
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Daily reminders for your habits',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> showHabitCompletedNotification(
    int id,
    String habitName,
  ) async {
    await _notifications.show(
      id,
      '✅ Habit Completed!',
      '$habitName marked as done! Keep it up! 🌟',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_completed',
          'Habit Completed',
          channelDescription: 'Confirmation when you complete a habit',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  static Future<void> checkAndCelebrateStreak(
    int id,
    String habitName,
    int streak,
  ) async {
    String? title;
    String? body;

    if (streak == 3) {
      title = '✨ Great Job!';
      body = '$habitName: 3 days in a row!';
    } else if (streak == 7) {
      title = '🎉 One Week Streak!';
      body = '$habitName: 7 days strong! Keep going!';
    } else if (streak == 10 || streak == 20) {
      title = '🔥 Keep it up!';
      body = '$habitName: $streak days! You\'re on fire!';
    } else if (streak == 30) {
      title = '🏆 30-Day Streak!';
      body = '$habitName: One month of consistency! Amazing!';
    } else if (streak == 100) {
      title = '💯 100-Day Streak!';
      body = '$habitName: LEGENDARY! You\'re unstoppable!';
    }

    if (title != null && body != null) {
      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'celebrations',
            'Celebrations',
            channelDescription: 'Streak milestones and achievements',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  static Future<void> scheduleEveningReminder(int incompleteCount) async {
    if (incompleteCount == 0) {
      // Cancel evening reminder if all habits are done
      await _notifications.cancel(999999);
      return;
    }

    await _notifications.zonedSchedule(
      999999,
      '🌙 Evening Check-in',
      'You have $incompleteCount habit${incompleteCount > 1 ? 's' : ''} left to complete today!',
      _nextInstanceOfTime(20, 0), // 8 PM
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'evening_reminders',
          'Evening Reminders',
          channelDescription: 'End of day check-ins',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Schedule afternoon reminder (2 PM check-in)
  static Future<void> scheduleAfternoonReminder(int incompleteCount) async {
    if (incompleteCount == 0) {
      await _notifications.cancel(999998);
      return;
    }

    await _notifications.zonedSchedule(
      999998,
      '☀️ Afternoon Check-in',
      'Don\'t forget your habits! $incompleteCount still pending.',
      _nextInstanceOfTime(14, 0), // 2 PM
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'evening_reminders',
          'Evening Reminders',
          channelDescription: 'End of day check-ins',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cancel all reminders for a habit
  static Future<void> cancelHabitReminder(int habitId) async {
    await _notifications.cancel(habitId);
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static String _getMotivationalMessage() {
    final messages = [
      'You got this! 💪',
      'Small steps lead to big changes! 🚀',
      'Your future self will thank you! 🌟',
      'Consistency is key! 🔑',
      'Make today count! ⭐',
      'You\'re building something great! 🏗️',
    ];
    messages.shuffle();
    return messages.first;
  }
}
