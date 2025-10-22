import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ added

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ✅ Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ Save UID locally for persistence
      if (credential.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('shopOwnerUID', credential.user!.uid);
      }

      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ Register with email, password, and role
  Future<User?> registerWithEmailPassword(
    String email,
    String password,
    String role,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // ✅ Save UID locally for persistence (for new shop owners)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('shopOwnerUID', credential.user!.uid);
      }

      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // ✅ Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    // Optional: You can clear stored UID here if you want
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.remove('shopOwnerUID');
  }

  // ✅ Fetch user role
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'] ?? 'Customer';
    } catch (e) {
      return 'Customer';
    }
  }
}
