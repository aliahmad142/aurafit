class TryOnResponse {
  final bool success;
  final String message;
  final String? resultImageBase64;

  TryOnResponse({
    required this.success,
    required this.message,
    this.resultImageBase64,
  });

  factory TryOnResponse.fromJson(Map<String, dynamic> json) {
    return TryOnResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      resultImageBase64: json['result_image_base64'],
    );
  }
}
