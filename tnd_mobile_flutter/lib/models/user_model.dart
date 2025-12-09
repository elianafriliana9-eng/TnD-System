/// User Model
/// Represents a user in the TND System
class UserModel {
  final String? token;
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? photoPath;
  final String role;
  final int? divisionId;
  final String? divisionName;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoPath,
    required this.role,
    this.divisionId,
    this.divisionName,
    required this.isActive,
    required this.createdAt,
    this.token,
  });

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      photoPath: json['photo_path'],
      role: json['role'] ?? 'staff',
      divisionId: json['division_id'] != null 
          ? (json['division_id'] is String 
              ? int.parse(json['division_id']) 
              : json['division_id'])
          : null,
      divisionName: json['division_name'],
      isActive: json['is_active'] == 1 || json['is_active'] == '1' || json['is_active'] == true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      token: json['token'],
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photo_path': photoPath,
      'role': role,
      'division_id': divisionId,
      'division_name': divisionName,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'token': token,
    };
  }

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is supervisor
  bool get isSupervisor => role == 'supervisor';

  /// Check if user is staff
  bool get isStaff => role == 'staff';
}
