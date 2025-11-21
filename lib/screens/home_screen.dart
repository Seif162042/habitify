import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import '../services/auth_service.dart';
import '../services/habit_service.dart';
import '../services/step_counter_service.dart';
import '../services/local_storage.dart';
import '../services/share_service.dart';
import '../services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'add_habit_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _authService = AuthService();
  final _habitService = HabitService();
  late int _selectedIndex;
  int _currentSteps = 0;
  int _stepGoal = 10000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // STATE RESTORATION: Restore last selected tab
    _selectedIndex = LocalStorageService.getSelectedTab();

    // Load step goal from local storage
    _stepGoal = LocalStorageService.getStepGoal();

    // Check and reset streaks on app startup
    _checkStreaks();

    // Schedule evening reminder check
    _scheduleEveningReminderCheck();

    // Start updating step count
    _startStepUpdates();

    // Check permissions on startup
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// LIFECYCLE: Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateSteps();
    } else if (state == AppLifecycleState.paused) {
      LocalStorageService.saveSelectedTab(_selectedIndex);
    }
  }

  void _scheduleEveningReminderCheck() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      await _habitService.checkIncompleteHabitsAndNotify(userId);
    }
  }

  void _checkStreaks() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      await _habitService.checkAndResetStreaks(userId);
    }
  }

  void _startStepUpdates() {
    _updateSteps();
    // Update every 30 seconds instead of 5 to reduce refresh rate
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _startStepUpdates();
      }
    });
  }

  void _updateSteps() {
    setState(() {
      _currentSteps = StepCounterService.getTodaySteps();
    });
  }

  /// PERMISSION SYSTEM: Check and request permissions
  Future<void> _checkPermissions() async {
    final activityStatus = await Permission.activityRecognition.status;

    if (activityStatus.isDenied && mounted) {
      // Show rationale for step counter
      await PermissionService.showPermissionRationale(
        context,
        title: '📊 Step Counter',
        message:
            'Habitify would like to track your daily steps to help you stay active!',
        permission: Permission.activityRecognition,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habitify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildHabitsTab(userId)
          : _selectedIndex == 1
              ? const LeaderboardScreen()
              : const ProfileScreen(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddHabitScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          LocalStorageService.saveSelectedTab(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsTab(String userId) {
    return Column(
      children: [
        // SENSOR DISPLAY: Step counter widget
        _buildStepCounterCard(),

        // Habits list
        Expanded(
          child: StreamBuilder<List<Habit>>(
            stream: _habitService.getUserHabits(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final habits = snapshot.data ?? [];

              if (habits.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.track_changes,
                          size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No habits yet!',
                        style: TextStyle(
                            fontSize: 20, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to create your first habit',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: habits.length,
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  return _buildHabitCard(habit, userId);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStepCounterCard() {
    final progress = _currentSteps / _stepGoal;
    final percentage = (progress * 100).clamp(0, 100).toInt();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_walk,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Steps Today',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$_currentSteps',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Goal: $_stepGoal',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress >= 1.0
                    ? '🎉 Goal reached! Amazing!'
                    : '${_stepGoal - _currentSteps} steps to go!',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              // INTER-APP COMMUNICATION: Share button
              if (_currentSteps > 0)
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                  onPressed: () {
                    ShareService.shareStepAchievement(
                      steps: _currentSteps,
                      goal: _stepGoal,
                    );
                  },
                  tooltip: 'Share your progress',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, String userId) {
    final today = DateTime.now();
    final isCompletedToday = habit.lastCompletedDate != null &&
        habit.lastCompletedDate!.toDate().day == today.day &&
        habit.lastCompletedDate!.toDate().month == today.month &&
        habit.lastCompletedDate!.toDate().year == today.year;

    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Habit'),
              content: Text(
                  'Are you sure you want to delete "${habit.name}"? This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        await _habitService.deleteHabit(habit.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${habit.name} deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  // Re-add the habit
                  _habitService.addHabit(habit);
                },
              ),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                isCompletedToday ? Colors.green : Colors.deepPurple,
            child: Icon(
              isCompletedToday ? Icons.check : Icons.track_changes,
              color: Colors.white,
            ),
          ),
          title: Text(
            habit.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (habit.description.isNotEmpty)
                Text(habit.description,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text('Streak: ${habit.streak} days'),
                  const Spacer(),
                  // INTER-APP COMMUNICATION: Share streak button
                  if (habit.streak > 0)
                    IconButton(
                      icon: const Icon(Icons.share, size: 18),
                      onPressed: () {
                        ShareService.shareHabitStreak(
                          habitName: habit.name,
                          streak: habit.streak,
                          points: habit.streak * 10,
                        );
                      },
                      tooltip: 'Share streak',
                    ),
                ],
              ),
            ],
          ),
          trailing: isCompletedToday
              ? const Icon(Icons.check_circle, color: Colors.green)
              : IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () async {
                    await _habitService.logHabitCompletion(habit.id, userId);
                    _scheduleEveningReminderCheck();
                  },
                ),
        ),
      ),
    );
  }
}
