import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<LeaderboardEntry>> getLeaderboard({int limit = 10}) {
    return _firestore
        .collection('users')
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final data = entry.value.data();
        return LeaderboardEntry(
          userId: entry.value.id,
          displayName: data['displayName'] ?? 'Anonymous',
          totalPoints: data['totalPoints'] ?? 0,
          rank: rank,
        );
      }).toList();
    });
  }

  Future<int?> getUserRank(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return null;

    final userPoints = userDoc.data()?['totalPoints'] ?? 0;

    final higherRankedUsers = await _firestore
        .collection('users')
        .where('totalPoints', isGreaterThan: userPoints)
        .get();

    return higherRankedUsers.docs.length + 1;
  }

  // Get user stats
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      return userDoc.data();
    } catch (e) {
      print('Error getting user stats: \$e');
      return null;
    }
  }
}
