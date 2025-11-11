import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import '../services/auth_service.dart';
import '../services/habit_service.dart';
import 'add_habit_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _habitService = HabitService();
  int _selectedIndex = 0;

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
    return StreamBuilder<List<HabitModel>>(
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
          return const Center(
            child: Text('No habits yet. Add one to get started!'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];
            final canComplete = habit.lastCompletedDate == null ||
                !_isSameDay(habit.lastCompletedDate!, DateTime.now());

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(habit.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.description),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text('Streak: ${habit.streak} days'),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    canComplete
                        ? Icons.check_circle_outline
                        : Icons.check_circle,
                    color: canComplete ? Colors.grey : Colors.green,
                  ),
                  onPressed: canComplete
                      ? () async {
                          await _habitService.completeHabit(habit.id, userId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Habit completed! +10 points'),
                              ),
                            );
                          }
                        }
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
