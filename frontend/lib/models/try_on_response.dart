class TryOnResponse {
  final bool success;
  final String message;
  final String? resultImageBase64;
  final String? resultImageUrl;
  final int? newCredits;

  TryOnResponse({
    required this.success,
    required this.message,
    this.resultImageBase64,
    this.resultImageUrl,
    this.newCredits,
  });

  factory TryOnResponse.fromJson(Map<String, dynamic> json) {
    return TryOnResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      resultImageBase64: json['result_image_base64'],
      resultImageUrl: json['result_image_url'],
      newCredits: json['new_credits'],
    );
  }
}
