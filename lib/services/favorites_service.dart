import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorited_points';

  /// Load all favorited point IDs from local storage
  static Future<Set<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesList = prefs.getStringList(_favoritesKey) ?? [];
    return Set<String>.from(favoritesList);
  }

  /// Save all favorited point IDs to local storage
  static Future<void> saveFavorites(Set<String> favoriteIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, favoriteIds.toList());
  }

  /// Toggle favorite status for a point
  static Future<void> toggleFavorite(String pointId) async {
    final favorites = await loadFavorites();
    if (favorites.contains(pointId)) {
      favorites.remove(pointId);
    } else {
      favorites.add(pointId);
    }
    await saveFavorites(favorites);
  }

  /// Check if a point is favorited
  static Future<bool> isFavorited(String pointId) async {
    final favorites = await loadFavorites();
    return favorites.contains(pointId);
  }
}
