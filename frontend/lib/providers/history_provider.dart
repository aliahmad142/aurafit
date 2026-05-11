import 'package:flutter/material.dart';
import '../models/history_item.dart';
import '../services/database_helper.dart';

class HistoryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<HistoryItem> _items = [];
  bool _isLoading = false;

  List<HistoryItem> get items => _items;
  bool get isLoading => _isLoading;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _dbHelper.getHistoryItems();
      debugPrint('Loaded ${_items.length} history items (Local)');
    } catch (e) {
      debugPrint('Error loading local history: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(HistoryItem item) async {
    try {
      await _dbHelper.insertHistoryItem(item);
      await loadHistory(); // refresh the list
    } catch (e) {
      debugPrint('Error saving history item: $e');
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      // Safely find the item — it may already be removed
      final item = _items.cast<HistoryItem?>().firstWhere((i) => i?.id == id, orElse: () => null);
      if (item != null) {
        // Delete associated favorite if exists
        await _dbHelper.deleteFavorite(item.resultImagePath);
        // Delete encrypted image files from disk
        await _dbHelper.deleteImageFiles(item);
      }
      await _dbHelper.deleteHistoryItem(id);
      _items.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting local history item: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _dbHelper.clearFavorites();
      await _dbHelper.clearHistory();
      await _dbHelper.clearAllImageFiles();
      _items.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing local history: $e');
    }
  }
}
