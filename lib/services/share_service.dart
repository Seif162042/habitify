import 'package:share_plus/share_plus.dart';

/// Service for inter-app communication via sharing
/// 
/// INTER-APP COMMUNICATION MECHANISMS:
/// 1. Android Intents (implicit) - Share to any app
/// 2. Share sheet - System UI for app selection
/// 3. Deep linking support (for receiving shares)
class ShareService {
  
  /// Share habit streak achievement
  /// Uses Android's ACTION_SEND intent
  static Future<void> shareHabitStreak({
    required String habitName,
    required int streak,
    required int points,
  }) async {
    final message = _buildStreakMessage(habitName, streak, points);
    
    await Share.share(
      message,
      subject: 'My Habitify Achievement! 🎉',
    );
  }
  
  /// Share overall progress
  static Future<void> shareOverallProgress({
    required int totalHabits,
    required int totalPoints,
    required int longestStreak,
  }) async {
    final message = '''
🎯 My Habitify Progress! 🎯

📊 Total Habits: $totalHabits
⭐ Points Earned: $totalPoints
🔥 Longest Streak: $longestStreak days

Building better habits, one day at a time! 💪

#Habitify #HabitTracking #PersonalGrowth
''';
    
    await Share.share(message);
  }
  
  /// Share step counter achievement
  static Future<void> shareStepAchievement({
    required int steps,
    required int goal,
  }) async {
    final percentage = ((steps / goal) * 100).toInt();
    final emoji = steps >= goal ? '🎉' : '🚶';
    
    final message = '''
$emoji Daily Steps Achievement! $emoji

👟 Steps Today: ${_formatNumber(steps)}
🎯 Goal: ${_formatNumber(goal)}
📊 Progress: $percentage%

${steps >= goal ? 'Goal crushed! 💪' : 'Making progress! 🌟'}

#Habitify #StepCounter #Fitness
''';
    
    await Share.share(message);
  }
  
  /// Share milestone celebration
  static Future<void> shareMilestone({
    required String habitName,
    required int milestone,
  }) async {
    String emoji = '🎉';
    String message = '';
    
    if (milestone == 7) {
      emoji = '🎉';
      message = 'One week strong!';
    } else if (milestone == 30) {
      emoji = '🏆';
      message = 'One month of consistency!';
    } else if (milestone == 100) {
      emoji = '💯';
      message = 'LEGENDARY status unlocked!';
    }
    
    final shareText = '''
$emoji $milestone-Day Streak! $emoji

Habit: $habitName
Streak: $milestone days
$message

Consistency is key! 🔑

#Habitify #$milestone DayStreak #Consistency
''';
    
    await Share.share(shareText);
  }
  
  /// Share with specific apps (if needed)
  /// Example: Share to WhatsApp, Twitter, etc.
  static Future<void> shareToSpecificApp({
    required String message,
    String? packageName,
  }) async {
    // Note: share_plus doesn't support app-specific sharing directly
    // This would require platform channels for Android Intent extras
    await Share.share(message);
  }
  
  /// Build formatted streak message
  static String _buildStreakMessage(String habitName, int streak, int points) {
    String emoji = '🔥';
    String encouragement = '';
    
    if (streak >= 100) {
      emoji = '💯';
      encouragement = 'LEGENDARY! Unstoppable!';
    } else if (streak >= 30) {
      emoji = '🏆';
      encouragement = 'One month strong!';
    } else if (streak >= 7) {
      emoji = '🎉';
      encouragement = 'One week down!';
    } else {
      emoji = '🔥';
      encouragement = 'Building momentum!';
    }
    
    return '''
$emoji $streak-Day Streak! $emoji

Habit: $habitName
Current Streak: $streak days
Points Earned: $points

$encouragement 💪

Track your habits with Habitify!
#Habitify #HabitTracking #$streak DayStreak
''';
  }
  
  /// Format large numbers with commas
  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '\${m[1]},',
    );
  }
}
