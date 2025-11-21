import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name - FIXED METHOD
      await userCredential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'displayName': displayName,
        'email': email,
        'points': 0,
        'totalHabitsCompleted': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException {
      print('❌ Sign up error: \${e.message}');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      print('❌ Sign in error: \${e.message}');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;

    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(currentUser!.uid).get();

      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('❌ Error getting user data: \$e');
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser!.uid).update(data);
    } catch (e) {
      print('❌ Error updating user data: \$e');
      rethrow;
    }
  }
}
