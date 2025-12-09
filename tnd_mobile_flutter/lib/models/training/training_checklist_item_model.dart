class TrainingChecklistItem {
  final int id;
  final int categoryId;
  final String itemText;
  final String? description;
  final int? sequenceOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TrainingChecklistItem({
    required this.id,
    required this.categoryId,
    required this.itemText,
    this.description,
    this.sequenceOrder,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory TrainingChecklistItem.fromJson(Map<String, dynamic> json) {
    return TrainingChecklistItem(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      categoryId: json['category_id'] is String
          ? int.parse(json['category_id'])
          : json['category_id'],
      itemText: json['item_text'] ?? '',
      description: json['description'],
      sequenceOrder: json['sequence_order'] is String
          ? int.tryParse(json['sequence_order'])
          : json['sequence_order'],
      isActive:
          json['is_active'] == 1 ||
          json['is_active'] == '1' ||
          json['is_active'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt:
          json['updated_at'] != null && json['updated_at'].toString().isNotEmpty
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'item_text': itemText,
      'description': description,
      'sequence_order': sequenceOrder,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
