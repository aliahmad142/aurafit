import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class FavoritesProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<dynamic> _favorites = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchFavorites() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _dbHelper.getFavorites();
      _favorites = data;
    } catch (e) {
      _errorMessage = "Failed to load local favorites";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFavorite(String imageUrl) async {
    try {
      await _dbHelper.insertFavorite(imageUrl);
      await fetchFavorites();
    } catch (e) {
      debugPrint("Error adding local favorite: $e");
    }
  }

  Future<void> removeFavorite(String imageUrl) async {
    try {
      await _dbHelper.deleteFavorite(imageUrl);
      await fetchFavorites();
    } catch (e) {
      debugPrint("Error removing local favorite: $e");
    }
  }

  Future<void> clearAll() async {
    try {
      final db = await _dbHelper.database;
      await db.delete('favorites');
      _favorites.clear();
      notifyListeners();
    } catch (e) {
      debugPrint("Error clearing local favorites: $e");
    }
  }

  bool isFavorited(String imageUrl) {
    return _favorites.any((item) => item['image_url'] == imageUrl);
  }

  // Legacy helper for compatibility
  int? getFavoriteId(String imageUrl) => 0; 
}
