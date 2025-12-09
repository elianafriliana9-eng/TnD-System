class TrainerModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? photoPath;
  final bool isActive;
  final DateTime createdAt;
  final String? token;

  TrainerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoPath,
    required this.isActive,
    required this.createdAt,
    this.token,
  });

  factory TrainerModel.fromJson(Map<String, dynamic> json) {
    return TrainerModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'trainer',
      photoPath: json['photo_path'],
      isActive: json['is_active'] == 1 || json['is_active'] == '1' || json['is_active'] == true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'photo_path': photoPath,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'token': token,
    };
  }
}