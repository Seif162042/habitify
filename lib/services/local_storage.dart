import 'package:shared_preferences/shared_preferences.dart';

/// Service for local state persistence
/// 
/// STATE RESTORATION FEATURES:
/// 1. Saves UI state (selected tab, preferences)
/// 2. Saves draft data (incomplete forms)
/// 3. Saves user preferences (notification settings)
/// 4. Persists across app restarts
class LocalStorageService {
  static SharedPreferences? _prefs;
  
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // ==================== UI STATE RESTORATION ====================
  
  static Future<void> saveSelectedTab(int index) async {
    await _prefs?.setInt('selected_tab', index);
  }
  
  static int getSelectedTab() {
    return _prefs?.getInt('selected_tab') ?? 0;
  }
  
  // ==================== DRAFT DATA RESTORATION ====================
  
  static Future<void> saveDraftHabit({
    required String name,
    required String description,
  }) async {
    await _prefs?.setString('draft_habit_name', name);
    await _prefs?.setString('draft_habit_description', description);
    await _prefs?.setBool('has_draft_habit', true);
  }
  
  static Map<String, String>? getDraftHabit() {
    final hasDraft = _prefs?.getBool('has_draft_habit') ?? false;
    if (!hasDraft) return null;
    
    return {
      'name': _prefs?.getString('draft_habit_name') ?? '',
      'description': _prefs?.getString('draft_habit_description') ?? '',
    };
  }
  
  static Future<void> clearDraftHabit() async {
    await _prefs?.remove('draft_habit_name');
    await _prefs?.remove('draft_habit_description');
    await _prefs?.setBool('has_draft_habit', false);
  }
  
  // ==================== USER PREFERENCES ====================
  
  static Future<void> saveNotificationEnabled(bool enabled) async {
    await _prefs?.setBool('notifications_enabled', enabled);
  }
  
  static bool getNotificationEnabled() {
    return _prefs?.getBool('notifications_enabled') ?? true;
  }
  
  static Future<void> saveNotificationTime(int hour, int minute) async {
    await _prefs?.setInt('notification_hour', hour);
    await _prefs?.setInt('notification_minute', minute);
  }
  
  static Map<String, int> getNotificationTime() {
    return {
      'hour': _prefs?.getInt('notification_hour') ?? 9,
      'minute': _prefs?.getInt('notification_minute') ?? 0,
    };
  }
  
  // ==================== APP STATE ====================
  
  static Future<void> setFirstLaunch(bool isFirst) async {
    await _prefs?.setBool('first_launch', isFirst);
  }
  
  static bool isFirstLaunch() {
    return _prefs?.getBool('first_launch') ?? true;
  }
  
  static Future<void> saveAppVersion(String version) async {
    await _prefs?.setString('app_version', version);
  }
  
  static String? getAppVersion() {
    return _prefs?.getString('app_version');
  }
  
  // ==================== STEP COUNTER DATA ====================
  
  static Future<void> saveStepGoal(int steps) async {
    await _prefs?.setInt('step_goal', steps);
  }
  
  static int getStepGoal() {
    return _prefs?.getInt('step_goal') ?? 10000;
  }
  
  // ==================== STATISTICS ====================
  
  static Future<void> saveTotalHabitsCreated(int count) async {
    await _prefs?.setInt('total_habits_created', count);
  }
  
  static int getTotalHabitsCreated() {
    return _prefs?.getInt('total_habits_created') ?? 0;
  }
  
  static Future<void> incrementHabitsCreated() async {
    final current = getTotalHabitsCreated();
    await saveTotalHabitsCreated(current + 1);
  }
  
  // ==================== CLEAR DATA ====================
  
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
  
  static Future<void> clearUIState() async {
    await _prefs?.remove('selected_tab');
    await clearDraftHabit();
  }
}
