import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class UserService {
  // Android emulator -> localhost on your computer
  static const String baseUrl = 'http://10.0.2.2:5022';


  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  /// Register a new user
  static Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Identity/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userName': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      String message = 'Registration failed';

      try {
        final body = jsonDecode(response.body);
        message = body.toString();
      } catch (_) {}

      throw Exception(message);
    }
  }

  /// Login
  static Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Invalid email or password');
    }

    final body = jsonDecode(response.body);

    final token = body['accessToken'];

    if (token == null) {
      throw Exception('No access token returned from server');
    }

    // Decode JWT payload.
    final parts = token.split('.');

    if (parts.length != 3) {
      throw Exception('Invalid JWT token');
    }

    final payload = jsonDecode(
      utf8.decode(
        base64Url.decode(
          base64Url.normalize(parts[1]),
        ),
      ),
    );

    final userId = payload['sub'] ?? '';
    final userEmail = payload['email'] ?? email;

    final user = User(
      id: userId,
      username: payload['unique_name'] ?? '',
      email: userEmail,
    );

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(
      _userKey,
      jsonEncode(user.toJson()),
    );

    return user;
  }

  /// Get stored JWT
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get current logged-in user
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();

    final userJson = prefs.getString(_userKey);

    if (userJson == null) {
      return null;
    }

    return User.fromJson(jsonDecode(userJson));
  }

  /// Check whether user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }
}