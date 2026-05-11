import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _pushNotifications = true;
  bool _hdRendering = false;
  bool _autoSaveToGallery = true;
  bool _isLoaded = false;

  bool get pushNotifications => _pushNotifications;
  bool get hdRendering => _hdRendering;
  bool get autoSaveToGallery => _autoSaveToGallery;
  bool get isLoaded => _isLoaded;

  static const _keyNotifications = 'pref_push_notifications';
  static const _keyHdRendering = 'pref_hd_rendering';
  static const _keyAutoSave = 'pref_auto_save_gallery';

  /// Load saved preferences from secure storage.
  Future<void> loadPreferences() async {
    try {
      final notif = await _storage.read(key: _keyNotifications);
      final hd = await _storage.read(key: _keyHdRendering);
      final autoSave = await _storage.read(key: _keyAutoSave);

      _pushNotifications = notif == null ? true : notif == 'true';
      _hdRendering = hd == null ? false : hd == 'true';
      _autoSaveToGallery = autoSave == null ? true : autoSave == 'true';

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setPushNotifications(bool value) async {
    _pushNotifications = value;
    notifyListeners();
    await _storage.write(key: _keyNotifications, value: value.toString());
  }

  Future<void> setHdRendering(bool value) async {
    _hdRendering = value;
    notifyListeners();
    await _storage.write(key: _keyHdRendering, value: value.toString());
  }

  Future<void> setAutoSaveToGallery(bool value) async {
    _autoSaveToGallery = value;
    notifyListeners();
    await _storage.write(key: _keyAutoSave, value: value.toString());
  }
}
