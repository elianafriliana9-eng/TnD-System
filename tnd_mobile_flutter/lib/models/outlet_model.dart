/// Outlet Model
/// Represents an outlet/store in the TND System
class OutletModel {
  final int id;
  final String name;
  final String code;
  final String? address;
  final String? region;
  final String? phone;
  final String? email;
  final String? managerName;
  final String status;
  final int? userId;
  final int? divisionId;
  final String? divisionName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  OutletModel({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.region,
    this.phone,
    this.email,
    this.managerName,
    this.status = 'active',
    this.userId,
    this.divisionId,
    this.divisionName,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create OutletModel from JSON
  factory OutletModel.fromJson(Map<String, dynamic> json) {
    return OutletModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      address: json['address'],
      region: json['region'],
      phone: json['phone'],
      email: json['email'],
      managerName: json['manager_name'],
      status: json['status'] ?? 'active',
      userId: json['user_id'] != null
          ? (json['user_id'] is String ? int.parse(json['user_id']) : json['user_id'])
          : null,
      divisionId: json['division_id'] != null
          ? (json['division_id'] is String ? int.parse(json['division_id']) : json['division_id'])
          : null,
      divisionName: json['division_name'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  /// Convert OutletModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'region': region,
      'phone': phone,
      'email': email,
      'manager_name': managerName,
      'status': status,
      'user_id': userId,
      'division_id': divisionId,
      'division_name': divisionName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to JSON for API create/update (without id and timestamps)
  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'code': code,
      'address': address,
      'region': region,
      'phone': phone,
      'email': email,
      'manager_name': managerName,
      'status': status,
      'user_id': userId,
      'division_id': divisionId,
    };
  }

  /// Get display location (address or region)
  String get displayLocation => address ?? region ?? 'No address';
}
