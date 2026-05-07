class User {
  final int id;
  final String name;
  final String email;
  final String planType;
  final int credits;
  final String? planExpiresAt;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.planType = 'FREE',
    this.credits = 5,
    this.planExpiresAt,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      planType: json['plan_type'] ?? 'FREE',
      credits: json['credits'] ?? 0,
      planExpiresAt: json['plan_expires_at'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'plan_type': planType,
      'credits': credits,
      'plan_expires_at': planExpiresAt,
      'created_at': createdAt,
    };
  }
}
