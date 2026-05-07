import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class FavoritesProvider with ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final AuthService _authService = AuthService();

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
      final token = await _authService.getAccessToken();
      final response = await _dio.get(
        '/api/favorites',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _favorites = response.data;
    } catch (e) {
      _errorMessage = "Failed to load favorites";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFavorite(String imageUrl) async {
    try {
      final token = await _authService.getAccessToken();
      await _dio.post(
        '/api/favorites/add',
        data: FormData.fromMap({'image_url': imageUrl}),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      fetchFavorites();
    } catch (e) {
      print("Error adding favorite: $e");
    }
  }

  Future<void> removeFavorite(int id) async {
    try {
      final token = await _authService.getAccessToken();
      await _dio.delete(
        '/api/favorites/remove/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _favorites.removeWhere((item) => item['id'] == id);
      notifyListeners();
    } catch (e) {
      print("Error removing favorite: $e");
    }
  }

  bool isFavorited(String imageUrl) {
    return _favorites.any((item) => item['image_url'] == imageUrl);
  }

  int? getFavoriteId(String imageUrl) {
    try {
      return _favorites.firstWhere((item) => item['image_url'] == imageUrl)['id'];
    } catch (e) {
      return null;
    }
  }
}
