import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/try_on_response.dart';
import '../models/history_item.dart';
import '../providers/history_provider.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

import '../providers/auth_provider.dart';

class VtoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  XFile? _personImage;
  XFile? _clothImage;
  bool _isLoading = false;
  String _loadingMessage = "Preparing images...";
  TryOnResponse? _result;
  String? _lastResultLocalPath;
  String? _errorMessage;
  String _category = 'auto';

  XFile? get personImage => _personImage;
  XFile? get clothImage => _clothImage;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  TryOnResponse? get result => _result;
  String? get lastResultLocalPath => _lastResultLocalPath;
  String? get errorMessage => _errorMessage;
  String get category => _category;

  void setCategory(String category) {
    _category = category;
    notifyListeners();
  }

  Future<XFile?> _cropImage(XFile image) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: AppColors.surface,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          activeControlsWidgetColor: AppColors.primary,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
        ),
      ],
    );
    if (croppedFile != null) {
      return XFile(croppedFile.path);
    }
    return null;
  }

  Future<bool> _requestPermission(ImageSource source) async {
    _errorMessage = null;
    Permission permission;
    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      // For gallery access
      // On Android 13+ (SDK 33+), we should use Permission.photos
      // On older Android, Permission.storage is used.
      // permission_handler handles most of this mapping.
      permission = Permission.photos;
      
      // Check if it's Android and SDK < 33
      // However, Permission.photos is generally the right way now for media.
    }

    var status = await permission.status;
    if (status.isGranted) return true;

    if (status.isDenied) {
      status = await permission.request();
      if (status.isGranted) return true;
    }

    if (status.isPermanentlyDenied) {
      _errorMessage = "Permission permanently denied. Please enable it in settings.";
      notifyListeners();
      // Optionally open settings
      // await openAppSettings();
      return false;
    }

    _errorMessage = "Permission required to access ${source == ImageSource.camera ? 'camera' : 'gallery'}.";
    notifyListeners();
    return false;
  }

  Future<void> pickPersonImage(ImageSource source) async {
    if (!await _requestPermission(source)) return;
    
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final cropped = await _cropImage(image);
      if (cropped != null) {
        _personImage = cropped;
        _errorMessage = null; // Clear error message on success
        notifyListeners();
      }
    }
  }

  Future<void> pickClothImage(ImageSource source) async {
    if (!await _requestPermission(source)) return;

    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final cropped = await _cropImage(image);
      if (cropped != null) {
        _clothImage = cropped;
        _errorMessage = null; // Clear error message on success
        notifyListeners();
      }
    }
  }

  Future<bool> processTryOn({
    HistoryProvider? historyProvider,
    AuthProvider? authProvider,
  }) async {
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
      
      if (_result?.success == false) {
        _errorMessage = _result?.message;
      } else if (_result?.success == true) {
        if (historyProvider != null) {
          await _saveToHistory(historyProvider);
        }
        if (authProvider != null) {
          await authProvider.refreshUser(); // Sync credits
        }
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
      _lastResultLocalPath = resultPath;
      notifyListeners();
      debugPrint('Successfully saved try-on to history (Filesystem)');
    } catch (e) {
      debugPrint('Error saving to history: $e');
    }
  }

  void reset() {
    _personImage = null;
    _clothImage = null;
    _result = null;
    _lastResultLocalPath = null;
    _errorMessage = null;
    _isLoading = false;
    // Keep _category so user doesn't have to re-select
    notifyListeners();
  }
}
