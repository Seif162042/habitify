import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import '../services/auth_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leaderboardService = LeaderboardService();
    final authService = AuthService();
    final currentUserId = authService.currentUser?.uid ?? '';

    return StreamBuilder<List<LeaderboardEntry>>(
      stream: leaderboardService.getLeaderboard(limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: \${snapshot.error}'));
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return const Center(
            child: Text('No users on the leaderboard yet!'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isCurrentUser = entry.userId == currentUserId;

            return Card(
              color: isCurrentUser ? Colors.deepPurple.shade50 : null,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRankColor(entry.rank),
                  child: Text(
                    '\${entry.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  entry.displayName,
                  style: TextStyle(
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '\${entry.totalPoints}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.deepPurple;
    }
  }
}
