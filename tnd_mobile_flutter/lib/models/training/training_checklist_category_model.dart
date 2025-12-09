class TrainingChecklistCategory {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final int? sequenceOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TrainingChecklistCategory({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    this.sequenceOrder,
    required this.createdAt,
    this.updatedAt,
  });

  factory TrainingChecklistCategory.fromJson(Map<String, dynamic> json) {
    return TrainingChecklistCategory(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      isActive: json['is_active'] == 1 || json['is_active'] == '1' || json['is_active'] == true,
      sequenceOrder: json['sequence_order'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'sequence_order': sequenceOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}