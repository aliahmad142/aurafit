import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

import '../providers/favorites_provider.dart';
import '../providers/history_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  /// Called once at app start to check if user is already logged in.
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First try reading the locally saved user
      final savedUser = await _authService.getSavedUser();
      final token = await _authService.getAccessToken();

      if (savedUser != null && token != null) {
        // Validate token by hitting /me
        final serverUser = await _authService.getProfile();
        if (serverUser != null) {
          _currentUser = serverUser;
        } else {
          // Token expired and refresh failed → clear
          await _authService.clearAll();
          _currentUser = null;
        }
      }
    } catch (_) {
      _currentUser = null;
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  /// Refresh all user-related data (credits, favorites, history).
  Future<void> refreshAllData(BuildContext context) async {
    if (_currentUser == null) return;
    
    // Refresh user profile (credits)
    await refreshUser();
    
    if (context.mounted) {
      // Refresh favorites
      Provider.of<FavoritesProvider>(context, listen: false).fetchFavorites();
      // Refresh history
      Provider.of<HistoryProvider>(context, listen: false).loadHistory();
    }
  }

  /// Register a new account.
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signup(
        name: name,
        email: email,
        password: password,
      );
      _currentUser = result['user'] as User;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Log in with email + password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );
      _currentUser = result['user'] as User;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Log out and clear all stored credentials.
  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear any displayed error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Request a password reset.
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset password.
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google.
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final googleUser = await _authService.signInWithGoogle();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        _errorMessage = "Could not get ID Token from Google";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final data = await _authService.googleLogin(idToken);
      _currentUser = data['user'] as User;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh current user data from server.
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getProfile();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  /// Simulate a successful payment and refresh user data.
  Future<void> simulatePaymentSuccess() async {
    _isLoading = true;
    notifyListeners();
    try {
      final updatedUser = await _authService.simulatePaymentSuccess();
      _currentUser = updatedUser;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
