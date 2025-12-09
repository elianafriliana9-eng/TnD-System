/// Checklist Category Model
/// Represents a category for grouping checklist items
class ChecklistCategoryModel {
  final int id;
  final String name;
  final String? description;
  final int divisionId;
  final int? sortOrder;
  final String status;
  final int itemsCount;
  final DateTime createdAt;

  ChecklistCategoryModel({
    required this.id,
    required this.name,
    this.description,
    required this.divisionId,
    this.sortOrder,
    required this.status,
    required this.itemsCount,
    required this.createdAt,
  });

  /// Create from JSON
  factory ChecklistCategoryModel.fromJson(Map<String, dynamic> json) {
    return ChecklistCategoryModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      divisionId: json['division_id'] is String 
          ? int.parse(json['division_id']) 
          : json['division_id'],
      sortOrder: json['sort_order'] != null
          ? (json['sort_order'] is String 
              ? int.parse(json['sort_order']) 
              : json['sort_order'])
          : null,
      status: json['status'] ?? 'active',
      itemsCount: json['items_count'] is String 
          ? int.parse(json['items_count']) 
          : (json['items_count'] ?? 0),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'division_id': divisionId,
      'sort_order': sortOrder,
      'status': status,
      'items_count': itemsCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Category Item Model (simplified version for category-based checklist)
class CategoryItemModel {
  final int id;
  final int categoryId;
  final String itemText;
  final int itemOrder;
  final bool isRequired;
  final DateTime createdAt;

  CategoryItemModel({
    required this.id,
    required this.categoryId,
    required this.itemText,
    required this.itemOrder,
    required this.isRequired,
    required this.createdAt,
  });

  /// Create from JSON
  factory CategoryItemModel.fromJson(Map<String, dynamic> json) {
    return CategoryItemModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      categoryId: json['category_id'] is String 
          ? int.parse(json['category_id']) 
          : json['category_id'],
      itemText: json['item_text'] ?? '',
      itemOrder: json['item_order'] is String 
          ? int.parse(json['item_order']) 
          : (json['item_order'] ?? 0),
      isRequired: json['is_required'] == 1 || 
                  json['is_required'] == '1' || 
                  json['is_required'] == true,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'item_text': itemText,
      'item_order': itemOrder,
      'is_required': isRequired ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
