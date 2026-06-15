import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

class UserService {
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  /// Register a new user (mock implementation)
  static Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    // In a real app, you'd send this to your backend
    // For now, we'll create a mock user
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      email: email,
    );

    await _saveUser(user);
    return user;
  }

  /// Login user (mock implementation)
  static Future<User> login({
    required String email,
    required String password,
  }) async {
    // In a real app, you'd validate against your backend
    // For now, we'll create a mock user based on email
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: email.split('@').first,
      email: email,
    );

    await _saveUser(user);
    return user;
  }

  /// Logout current user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  /// Get current logged-in user
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      final json = jsonDecode(userJson);
      return User.fromJson(json);
    }
    return null;
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  /// Save user to local storage
  static Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
