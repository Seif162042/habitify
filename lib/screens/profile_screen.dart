import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/share_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userId = authService.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final displayName = userData?['displayName'] ?? 'User';
        final email = userData?['email'] ?? '';
        final points = userData?['points'] ?? 0;
        final totalHabitsCompleted = userData?['totalHabitsCompleted'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  displayName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Points',
                      '$points',
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Completed',
                      '$totalHabitsCompleted',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Get longest streak
              FutureBuilder<int>(
                future: _getLongestStreak(userId),
                builder: (context, streakSnapshot) {
                  final longestStreak = streakSnapshot.data ?? 0;

                  return Column(
                    children: [
                      _buildStatCard(
                        context,
                        'Longest Streak',
                        '$longestStreak days',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                      const SizedBox(height: 24),

                      // INTER-APP COMMUNICATION: Share overall progress
                      ElevatedButton.icon(
                        onPressed: () async {
                          final habits = await FirebaseFirestore.instance
                              .collection('habits')
                              .where('userId', isEqualTo: userId)
                              .get();

                          ShareService.shareOverallProgress(
                            totalHabits: habits.docs.length,
                            totalPoints: points,
                            longestStreak: longestStreak,
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share My Progress'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _getLongestStreak(String userId) async {
    final habits = await FirebaseFirestore.instance
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .get();

    int longestStreak = 0;
    for (var doc in habits.docs) {
      final streak = doc.data()['streak'] ?? 0;
      if (streak > longestStreak) {
        longestStreak = streak;
      }
    }

    return longestStreak;
  }
}
