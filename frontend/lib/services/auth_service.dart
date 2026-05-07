import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '726168939124-6k8vo58hutrctedp1htavs8mvn8q4qe7.apps.googleusercontent.com',
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';

  // ─── Google Auth ──────────────────────────────────────────────

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      print('Error during Google Sign-In: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await clearAll();
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    try {
      final response = await _dio.post('/api/auth/google', data: {
        'id_token': idToken,
      });

      final data = response.data;
      await _saveTokens(data['access_token'], data['refresh_token']);
      await _saveUser(data['user']);

      return {
        'user': User.fromJson(data['user']),
        'access_token': data['access_token'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Payments & Subscriptions ──────────────────────────────────

  Future<Map<String, dynamic>> initiatePayment(String plan) async {
    try {
      final response = await _dio.post('/api/payment/initiate-payment', queryParameters: {
        'plan': plan,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> simulatePaymentSuccess() async {
    try {
      final response = await _dio.post('/api/payment/simulate-success');
      final user = User.fromJson(response.data);
      await _saveUser(user.toJson());
      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Token Management ──────────────────────────────────────────

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> _saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  Future<void> _saveUser(Map<String, dynamic> userJson) async {
    await _storage.write(
      key: _userKey,
      value: userJson.entries.map((e) => '${e.key}=${e.value}').join('||'),
    );
  }

  Future<User?> getSavedUser() async {
    final data = await _storage.read(key: _userKey);
    if (data == null) return null;
    try {
      final map = <String, dynamic>{};
      for (final pair in data.split('||')) {
        final idx = pair.indexOf('=');
        if (idx == -1) continue;
        final key = pair.substring(0, idx);
        final value = pair.substring(idx + 1);
        if (key == 'id') {
          map[key] = int.tryParse(value) ?? 0;
        } else {
          map[key] = value == 'null' ? null : value;
        }
      }
      return User.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // ─── Auth API Calls ────────────────────────────────────────────

  /// Sign up a new user. Returns a map with 'user' and tokens, or throws.
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/api/auth/signup', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      final data = response.data;
      await _saveTokens(data['access_token'], data['refresh_token']);
      await _saveUser(data['user']);

      return {
        'user': User.fromJson(data['user']),
        'access_token': data['access_token'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Log in an existing user. Returns a map with 'user' and tokens, or throws.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      await _saveTokens(data['access_token'], data['refresh_token']);
      await _saveUser(data['user']);

      return {
        'user': User.fromJson(data['user']),
        'access_token': data['access_token'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Refresh the access token using the stored refresh token.
  Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _dio.post('/api/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      final data = response.data;
      await _saveTokens(data['access_token'], data['refresh_token']);
      await _saveUser(data['user']);
      return true;
    } catch (_) {
      await clearAll();
      return false;
    }
  }

  /// Get current user profile from server (validates the token is still good).
  Future<User?> getProfile() async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '/api/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Try refreshing
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          final newToken = await getAccessToken();
          final response = await _dio.get(
            '/api/auth/me',
            options: Options(headers: {'Authorization': 'Bearer $newToken'}),
          );
          return User.fromJson(response.data);
        }
      }
      return null;
    }
  }

  /// Request a password reset code.
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _dio.post('/api/auth/forgot-password', data: {
        'email': email,
      });
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Reset password with a code.
  Future<String> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post('/api/auth/reset-password', data: {
        'email': email,
        'token': token,
        'new_password': newPassword,
      });
      return response.data['message'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ─── Error Handling ────────────────────────────────────────────

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('detail')) {
        return data['detail'].toString();
      }
      return 'Server error: ${e.response?.statusCode}';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Could not connect to server. Please check your network.';
    }
    return 'Something went wrong. Please try again.';
  }
}
