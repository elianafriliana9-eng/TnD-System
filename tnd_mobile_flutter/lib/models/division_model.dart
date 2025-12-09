/// Division Model
/// Represents a division/department in the TND System
class DivisionModel {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;

  DivisionModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  /// Create DivisionModel from JSON
  factory DivisionModel.fromJson(Map<String, dynamic> json) {
    return DivisionModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert DivisionModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
