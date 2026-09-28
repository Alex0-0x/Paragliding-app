import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'user_service.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorited_points';

  static const String baseUrl = 'http://10.0.2.2:5022';

  /// Get authentication headers
  static Future<Map<String, String>> _headers() async {
    final token = await UserService.getToken();

    if (token == null) {
      throw Exception('User is not logged in');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Load favorites
  ///
  /// Logged in  -> database
  /// Logged out -> SharedPreferences
  static Future<Set<String>> loadFavorites() async {
    final loggedIn = await UserService.isLoggedIn();

    if (!loggedIn) {
      return _loadLocalFavorites();
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/Favorites'),
      headers: await _headers(),
    );

    if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load favorites: ${response.statusCode}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((id) => id.toString())
        .toSet();
  }

  /// Load local anonymous favorites
  static Future<Set<String>> _loadLocalFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    final favoritesList =
        prefs.getStringList(_favoritesKey) ?? [];

    return Set<String>.from(favoritesList);
  }

  /// Save local favorites
  static Future<void> saveFavorites(
      Set<String> favoriteIds) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _favoritesKey,
      favoriteIds.toList(),
    );
  }

  /// Toggle favorite
  static Future<void> toggleFavorite(String pointId) async {
    final loggedIn = await UserService.isLoggedIn();

    if (!loggedIn) {
      final favorites = await _loadLocalFavorites();

      if (favorites.contains(pointId)) {
        favorites.remove(pointId);
      } else {
        favorites.add(pointId);
      }

      await saveFavorites(favorites);
      return;
    }

    final favorites = await loadFavorites();

    if (favorites.contains(pointId)) {
      await _removeFromDatabase(pointId);
    } else {
      await _addToDatabase(pointId);
    }
  }

  /// Check favorite status
  static Future<bool> isFavorited(String pointId) async {
    final favorites = await loadFavorites();

    return favorites.contains(pointId);
  }

  static Future<void> _addToDatabase(String pointId) async {
    final spotId = int.parse(pointId);

    final response = await http.post(
      Uri.parse('$baseUrl/api/Favorites/$spotId'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to add favorite: ${response.statusCode}',
      );
    }
  }

  static Future<void> _removeFromDatabase(String pointId) async {
    final spotId = int.parse(pointId);

    final response = await http.delete(
      Uri.parse('$baseUrl/api/Favorites/$spotId'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to remove favorite: ${response.statusCode}',
      );
    }
  }

  /// Transfer anonymous/local favorites to database
  static Future<void> migrateLocalFavorites() async {
    final loggedIn = await UserService.isLoggedIn();

    if (!loggedIn) {
      return;
    }

    final localFavorites = await _loadLocalFavorites();

    if (localFavorites.isEmpty) {
      return;
    }

    final spotIds = localFavorites
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toList();

    if (spotIds.isEmpty) {
      return;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/Favorites/migrate'),
      headers: await _headers(),
      body: jsonEncode(spotIds),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to migrate favorites: ${response.statusCode}',
      );
    }

    // Migration succeeded.
    // Local anonymous favorites are no longer needed.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
  }
}