import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? getCurrentUser() => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<User?> signUp(String email, String password) async {
    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return cred.user;
    } catch (e) {
      throw Exception("Signup failed: $e");
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return cred.user;
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    notifyListeners();
  }
}
