class HistoryItem {
  final int? id;
  final String resultImagePath;
  final String? personImagePath;
  final String? clothImagePath;
  final String createdAt;

  HistoryItem({
    this.id,
    required this.resultImagePath,
    this.personImagePath,
    this.clothImagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'result_image_path': resultImagePath,
      'person_image_path': personImagePath,
      'cloth_image_path': clothImagePath,
      'created_at': createdAt,
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'] as int?,
      resultImagePath: map['result_image_path'] as String,
      personImagePath: map['person_image_path'] as String?,
      clothImagePath: map['cloth_image_path'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
