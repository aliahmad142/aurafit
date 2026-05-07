import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final _storage = const FlutterSecureStorage();
  static const _keyAlias = 'vto_encryption_key';
  
  late encrypt.Key _key;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    String? base64Key = await _storage.read(key: _keyAlias);
    
    if (base64Key == null) {
      // Generate a new random 32-byte key
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      base64Key = base64Encode(values);
      await _storage.write(key: _keyAlias, value: base64Key);
    }

    _key = encrypt.Key.fromBase64(base64Key);
    _isInitialized = true;
  }

  Uint8List encryptBytes(Uint8List plaintext) {
    if (!_isInitialized) throw Exception('EncryptionService not initialized');

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
    
    final encrypted = encrypter.encryptBytes(plaintext, iv: iv);
    
    // Combine IV + Ciphertext
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);
    
    return combined;
  }

  Uint8List decryptBytes(Uint8List combined) {
    if (!_isInitialized) throw Exception('EncryptionService not initialized');

    if (combined.length < 16) throw Exception('Invalid encrypted data');

    // Extract IV (first 16 bytes)
    final iv = encrypt.IV(combined.sublist(0, 16));
    final ciphertext = combined.sublist(16);
    
    final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(ciphertext), iv: iv);
    
    return Uint8List.fromList(decrypted);
  }
}
