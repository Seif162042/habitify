import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final leaderboardService = LeaderboardService();
    final userId = authService.currentUser?.uid ?? '';

    return FutureBuilder<UserModel?>(
      future: authService.getUserData(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Error loading profile'));
        }

        final user = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 60,
                child: Icon(Icons.person, size: 60),
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            context,
                            'Total Points',
                            '\${user.totalPoints}',
                            Icons.stars,
                            Colors.amber,
                          ),
                          FutureBuilder<int?>(
                            future: leaderboardService.getUserRank(userId),
                            builder: (context, rankSnapshot) {
                              final rank = rankSnapshot.data ?? 0;
                              return _buildStatColumn(
                                context,
                                'Rank',
                                '#\$rank',
                                Icons.leaderboard,
                                Colors.deepPurple,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Member Since'),
                  subtitle: Text(
                    '\${user.createdAt.day}/\${user.createdAt.month}/\${user.createdAt.year}',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }
}
