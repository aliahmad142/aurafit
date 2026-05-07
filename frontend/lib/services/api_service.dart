import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/try_on_response.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class ApiService {
  final Dio _dio;
  final AuthService _authService = AuthService();

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 180),
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Inject auth token into every request
        final token = await _authService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // If 401, try refreshing the token and retry once
        if (error.response?.statusCode == 401) {
          final refreshed = await _authService.refreshAccessToken();
          if (refreshed) {
            final token = await _authService.getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<TryOnResponse> uploadImages({
    required XFile personImage,
    required XFile clothImage,
    String category = 'auto',
  }) async {
    try {
      final personBytes = await personImage.readAsBytes();
      final clothBytes = await clothImage.readAsBytes();

      FormData formData = FormData.fromMap({
        'person_image': MultipartFile.fromBytes(
          personBytes,
          filename: personImage.name,
        ),
        'cloth_image': MultipartFile.fromBytes(
          clothBytes,
          filename: clothImage.name,
        ),
        'category': category,
      });

      Response response = await _dio.post(
        '/api/try-on',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return TryOnResponse.fromJson(response.data);
      } else {
        return TryOnResponse(
          success: false,
          message: 'Server error: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMessage = "Failed to connect to server";
      if (e.response != null) {
        errorMessage = e.response?.data['detail'] ?? e.message;
      }
      return TryOnResponse(success: false, message: errorMessage);
    } catch (e) {
      return TryOnResponse(success: false, message: e.toString());
    }
  }
}
