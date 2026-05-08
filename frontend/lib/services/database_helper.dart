import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/history_item.dart';
import 'encryption_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  final EncryptionService _encryptionService = EncryptionService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'vto_history_v4.db'); // Incremented to v4 for encrypted storage
    debugPrint('DB: Initializing at $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        debugPrint('DB: Creating history_v2 table...');
        await db.execute('''
          CREATE TABLE history_v2 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            result_image_path TEXT NOT NULL,
            person_image_path TEXT,
            cloth_image_path TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image_url TEXT NOT NULL UNIQUE,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Saves a base64 string to an encrypted file and returns the path
  Future<String> saveImageToFile(String base64Str, String prefix) async {
    try {
      final plaintextBytes = base64Decode(base64Str);
      
      // Encrypt the bytes
      final encryptedBytes = _encryptionService.encryptBytes(Uint8List.fromList(plaintextBytes));
      
      final directory = await getApplicationDocumentsDirectory();
      final historyDir = Directory(p.join(directory.path, 'history_images'));
      if (!await historyDir.exists()) {
        await historyDir.create(recursive: true);
      }
      
      final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.enc';
      final file = File(p.join(historyDir.path, fileName));
      await file.writeAsBytes(encryptedBytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving encrypted image to file: $e');
      rethrow;
    }
  }

  /// Reads an encrypted file and returns decrypted bytes
  Future<Uint8List> readImageFile(String path) async {
    try {
      final file = File(path);
      final encryptedBytes = await file.readAsBytes();
      return _encryptionService.decryptBytes(encryptedBytes);
    } catch (e) {
      debugPrint('Error reading/decrypting image file: $e');
      rethrow;
    }
  }

  /// Decrypts an image to a temporary plaintext file (for sharing/saving to gallery)
  Future<String> decryptToTempFile(String encPath) async {
    try {
      final decryptedBytes = await readImageFile(encPath);
      final tempDir = await getTemporaryDirectory();
      final tempPath = p.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.png');
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(decryptedBytes);
      return tempPath;
    } catch (e) {
      debugPrint('Error creating temp decrypted file: $e');
      rethrow;
    }
  }

  Future<int> insertHistoryItem(HistoryItem item) async {
    try {
      final db = await database;
      debugPrint('DB: Inserting into history_v2...');
      final id = await db.insert('history_v2', item.toMap());
      debugPrint('DB: Insert successful, ID: $id');
      return id;
    } catch (e) {
      debugPrint('DB ERROR (insert): $e');
      rethrow;
    }
  }

  Future<List<HistoryItem>> getHistoryItems() async {
    try {
      final db = await database;
      debugPrint('DB: Fetching from history_v2...');
      final maps = await db.query(
        'history_v2',
        orderBy: 'created_at DESC',
      );
      debugPrint('DB: Found ${maps.length} items');
      return maps.map((map) => HistoryItem.fromMap(map)).toList();
    } catch (e) {
      debugPrint('DB ERROR (query): $e');
      return [];
    }
  }

  Future<int> deleteHistoryItem(int id) async {
    final db = await database;
    // Note: In a full implementation, we should also delete the files on disk here.
    return await db.delete('history_v2', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearHistory() async {
    final db = await database;
    return await db.delete('history_v2');
  }

  // ─── Favorites ──────────────────────────────────────────────────

  Future<int> insertFavorite(String imageUrl) async {
    try {
      final db = await database;
      return await db.insert('favorites', {
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      debugPrint('DB ERROR (insertFavorite): $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final db = await database;
      return await db.query('favorites', orderBy: 'created_at DESC');
    } catch (e) {
      debugPrint('DB ERROR (getFavorites): $e');
      return [];
    }
  }

  Future<int> deleteFavorite(String imageUrl) async {
    final db = await database;
    return await db.delete('favorites', where: 'image_url = ?', whereArgs: [imageUrl]);
  }
}
