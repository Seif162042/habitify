import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepCounterService {
  static StreamSubscription<StepCount>? _stepCountSubscription;
  static int _todaySteps = 0;
  static int _initialSteps = 0;
  static bool _isInitialized = false;

  // Get today's step count
  static int getTodaySteps() => _todaySteps;

  // Initialize step counter
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Check permission
    final status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      print('⚠️ Activity recognition permission not granted');
      return;
    }

    try {
      // Load saved steps for today
      final prefs = await SharedPreferences.getInstance();
      _todaySteps = prefs.getInt('today_steps') ?? 0;

      // Check if it's a new day
      final lastDate = prefs.getString('last_step_date') ?? '';
      final today = _getTodayDateKey();

      if (lastDate != today) {
        // New day - reset counter
        _todaySteps = 0;
        _initialSteps = 0;
        await prefs.setInt('today_steps', 0);
        await prefs.setString('last_step_date', today);
      }

      // Start listening to step counter
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
      );

      _isInitialized = true;
      print('✅ Step counter initialized');
    } catch (e) {
      print('❌ Error initializing step counter: $e');
    }
  }

  // Handle step count updates
  static void _onStepCount(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();

    if (_initialSteps == 0) {
      // First reading - set as baseline
      _initialSteps = event.steps;
      print('📊 Initial steps: $_initialSteps');
    }

    // Calculate steps since app started
    final stepsSinceStart = event.steps - _initialSteps;

    // Add to saved steps
    final savedSteps = prefs.getInt('today_steps') ?? 0;
    _todaySteps = savedSteps + stepsSinceStart;

    // Reset initial for next update
    _initialSteps = event.steps;

    // Save to storage
    await prefs.setInt('today_steps', _todaySteps);

    print('🚶 Today steps: $_todaySteps');
  }

  // Handle step count errors
  static void _onStepCountError(error) {
    print('❌ Step count error: $error');
  }

  // Stop step counter
  static void dispose() {
    _stepCountSubscription?.cancel();
    _stepCountSubscription = null;
    _isInitialized = false;
  }

  // Request permission
  static Future<bool> requestPermission() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  // Check if permission is granted
  static Future<bool> hasPermission() async {
    final status = await Permission.activityRecognition.status;
    return status.isGranted;
  }

  // Get step goal
  static Future<int> getStepGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('step_goal') ?? 10000;
  }

  // Set step goal
  static Future<void> setStepGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('step_goal', goal);
  }

  // Get today's date key - FIXED: Using proper string interpolation
  static String _getTodayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Get step history (last 7 days)
  static Future<Map<String, int>> getStepHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = <String, int>{};

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      history[dateKey] = prefs.getInt('steps_$dateKey') ?? 0;
    }
    return history;
  }
}
