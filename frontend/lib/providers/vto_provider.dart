import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../models/try_on_response.dart';
import '../models/history_item.dart';
import '../providers/history_provider.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';

class VtoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  XFile? _personImage;
  XFile? _clothImage;
  bool _isLoading = false;
  String _loadingMessage = "Preparing images...";
  TryOnResponse? _result;
  String? _errorMessage;
  String _category = 'auto';

  XFile? get personImage => _personImage;
  XFile? get clothImage => _clothImage;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  TryOnResponse? get result => _result;
  String? get errorMessage => _errorMessage;
  String get category => _category;

  void setCategory(String category) {
    _category = category;
    notifyListeners();
  }

  Future<void> pickPersonImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      _personImage = image;
      notifyListeners();
    }
  }

  Future<void> pickClothImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      _clothImage = image;
      notifyListeners();
    }
  }

  Future<bool> processTryOn({HistoryProvider? historyProvider}) async {
    if (_personImage == null || _clothImage == null) {
      _errorMessage = "Please select both images";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _loadingMessage = "Preparing model...";
    _errorMessage = null;
    _result = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _loadingMessage = "Fitting garment...";
      notifyListeners();

      _result = await _apiService.uploadImages(
        personImage: _personImage!,
        clothImage: _clothImage!,
        category: _category,
      );

      _loadingMessage = "Generating result...";
      notifyListeners();
      
      debugPrint('API Result: success=${_result?.success}, historyProvider=${historyProvider != null}');
      
      if (_result?.success == false) {
        _errorMessage = _result?.message;
      } else if (_result?.success == true && historyProvider != null) {
        debugPrint('Condition met, saving to history...');
        await _saveToHistory(historyProvider);
      }
      
      _isLoading = false;
      notifyListeners();
      return _result?.success ?? false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = "An unexpected error occurred: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveToHistory(HistoryProvider historyProvider) async {
    try {
      if (_result?.resultImageBase64 == null) {
        debugPrint('Cannot save to history: resultImageBase64 is null');
        return;
      }

      final dbHelper = DatabaseHelper();

      // Save images to local files to avoid SQLite "Row too big" error
      String resultPath = await dbHelper.saveImageToFile(_result!.resultImageBase64!, 'result');
      
      String? personPath;
      String? clothPath;

      if (_personImage != null) {
        final bytes = await _personImage!.readAsBytes();
        personPath = await dbHelper.saveImageToFile(base64Encode(bytes), 'person');
      }
      if (_clothImage != null) {
        final bytes = await _clothImage!.readAsBytes();
        clothPath = await dbHelper.saveImageToFile(base64Encode(bytes), 'cloth');
      }

      final item = HistoryItem(
        resultImagePath: resultPath,
        personImagePath: personPath,
        clothImagePath: clothPath,
        createdAt: DateTime.now().toIso8601String(),
      );

      await historyProvider.addItem(item);
      debugPrint('Successfully saved try-on to history (Filesystem)');
    } catch (e) {
      debugPrint('Error saving to history: $e');
    }
  }

  void reset() {
    _personImage = null;
    _clothImage = null;
    _result = null;
    _errorMessage = null;
    _isLoading = false;
    // Keep _category so user doesn't have to re-select
    notifyListeners();
  }
}
