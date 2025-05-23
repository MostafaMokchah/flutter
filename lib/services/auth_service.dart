import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mon_sirh_mobile/models/user.dart';

class AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _userIdKey = 'user_id';

  AuthService();

  Future<User?> login(String email, String password) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final uid = userCred.user?.uid;
      if (uid == null) {
        print('Login failed: No user ID returned');
        return null;
      }

      // Save UID locally for auto-login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, uid);

      return await _fetchUser(uid);
    } catch (e, stacktrace) {
      print('Login Error: $e');
      print(stacktrace);
      return null;
    }
  }

  Future<User?> register(String email, String password) async {
  try {
    final userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = userCred.user?.uid;

    if (uid == null) {
      print('Registration failed: No user ID returned');
      return null;
    }

    final userData = {
      'email': email,
      'name': '',
      'role': 'employee',
    };

    try {
      await _firestore.collection('users').doc(uid).set(userData);
      print('User document created successfully in Firestore');
    } catch (e) {
      print('Error writing user document to Firestore: $e');
      return null; // Fail registration if Firestore write fails
    }

    // Save UID locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, uid);

    return User(
      id: uid,
      email: email,
      name: '',
      role: UserRole.employee,
    );
  } catch (e) {
    print('Registration Error: $e');
    return null;
  }
}


  Future<void> logout() async {
    try {
      await _auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);

      print('User logged out');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  Future<bool> isAuthenticated() async {
    final user = _auth.currentUser;
    return user != null;
  }

  Future<User?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      print('Firebase user found: ${fbUser.uid}');
      return await _fetchUser(fbUser.uid);
    }
    print('No Firebase user found');
    return null;
  }

  Future<User?> _fetchUser(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        return User(
          id: uid,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          role: UserRole.values.firstWhere(
            (e) => e.toString() == 'UserRole.${data['role']}',
            orElse: () => UserRole.employee,
          ),
        );
      } else {
        print('User document does not exist');
        return null;
      }
    } catch (e) {
      print('Error fetching user from Firestore: $e');
      return null;
    }
  }
}
