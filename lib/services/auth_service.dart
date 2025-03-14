import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart' as app;

class AuthService {
  final FirebaseAuth _auth;
  final SharedPreferences _prefs;
  
  // Constructor that accepts FirebaseAuth and SharedPreferences instances
  AuthService({
    required FirebaseAuth auth,
    required SharedPreferences prefs,
  }) : _auth = auth,
       _prefs = prefs;
  
  // SharedPreferences keys
  static const String _userKey = 'user_data';
  static const String _authTokenKey = 'auth_token';
  
  // Register a new user with email and password
  Future<app.User?> register(String email, String password, String name, String phoneNumber) async {
    try {
      // Create user in Firebase
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      
      // Get ID token
      final String? token = await userCredential.user?.getIdToken();
      
      if (userCredential.user != null) {
        // Create app user model
        // Create app user model
        final app.User user = app.User(
          id: userCredential.user!.uid,
          email: email,
          name: name,
          phoneNumber: phoneNumber,
          authToken: token,
        );
        // Save user data to SharedPreferences
        await saveUserToPrefs(user);
        
        return user;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }
  
  // Login with email and password
  Future<app.User?> login(String email, String password) async {
    try {
      // Sign in with Firebase
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Get ID token
      final String? token = await userCredential.user?.getIdToken();
      
      if (userCredential.user != null) {
        // Create app user model
        final app.User user = app.User(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? email,
          name: userCredential.user!.displayName ?? '',
          authToken: token,
        );
        
        // Save user data to SharedPreferences
        await saveUserToPrefs(user);
        
        return user;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }
  
  // Logout user
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await clearUserFromPrefs();
    } catch (e) {
      rethrow;
    }
  }
  
  // Get current user from Firebase or SharedPreferences
  Future<app.User?> getCurrentUser() async {
    try {
      // Check Firebase auth state
      final User? firebaseUser = _auth.currentUser;
      
      if (firebaseUser != null) {
        // Get fresh token
        final String? token = await firebaseUser.getIdToken(true);
        
        return app.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? '',
          authToken: token,
        );
      } else {
        // Try to get from SharedPreferences
        return getUserFromPrefs();
      }
    } catch (e) {
      return null;
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      return true;
    }
    
    // Check if we have user data in SharedPreferences
    final app.User? user = await getUserFromPrefs();
    return user != null;
  }
  
  // Save user data to SharedPreferences
  Future<void> saveUserToPrefs(app.User user) async {
    try {
      final String userData = jsonEncode(user.toMap());
      
      await _prefs.setString(_userKey, userData);
      
      // Store auth token separately for easier access
      if (user.authToken != null) {
        await _prefs.setString(_authTokenKey, user.authToken!);
      }
    } catch (e) {
      print('Error saving user data: $e');
    }
  }
  
  // Get user data from SharedPreferences
  Future<app.User?> getUserFromPrefs() async {
    try {
      final String? userData = _prefs.getString(_userKey);
      
      if (userData != null && userData.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userData);
        return app.User.fromMap(userMap);
      }
    } catch (e) {
      print('Error retrieving user data: $e');
    }
    return null;
  }
  
  // Get auth token from SharedPreferences
  Future<String?> getAuthToken() async {
    try {
      return _prefs.getString(_authTokenKey);
    } catch (e) {
      print('Error retrieving auth token: $e');
      return null;
    }
  }
  
  // Clear user data from SharedPreferences
  Future<void> clearUserFromPrefs() async {
    try {
      await _prefs.remove(_userKey);
      await _prefs.remove(_authTokenKey);
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }
}

