import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document in Firestore
    await _firestore.collection('users').doc(userCredential.user!.uid).set(
      UserModel(
        id: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      ).toMap(),
    );

    return userCredential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
