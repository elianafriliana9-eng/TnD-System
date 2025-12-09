/// Checklist Template Model
/// Template for visit checklists
class ChecklistTemplateModel {
  final int id;
  final String name;
  final String? description;
  final int? divisionId;
  final bool isActive;
  final List<ChecklistItemModel>? items;
  final DateTime createdAt;

  ChecklistTemplateModel({
    required this.id,
    required this.name,
    this.description,
    this.divisionId,
    required this.isActive,
    this.items,
    required this.createdAt,
  });

  /// Create from JSON
  factory ChecklistTemplateModel.fromJson(Map<String, dynamic> json) {
    return ChecklistTemplateModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      divisionId: json['division_id'] != null
          ? (json['division_id'] is String
              ? int.parse(json['division_id'])
              : json['division_id'])
          : null,
      isActive: json['is_active'] == 1 || json['is_active'] == '1' || json['is_active'] == true,
      items: json['items'] != null
          ? (json['items'] as List).map((item) => ChecklistItemModel.fromJson(item)).toList()
          : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'division_id': divisionId,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Checklist Item Model
/// Individual item in a checklist template
class ChecklistItemModel {
  final int id;
  final int templateId;
  final String itemText;
  final String? category;
  final int itemOrder;
  final bool isRequired;
  final DateTime createdAt;

  ChecklistItemModel({
    required this.id,
    required this.templateId,
    required this.itemText,
    this.category,
    required this.itemOrder,
    required this.isRequired,
    required this.createdAt,
  });

  /// Create from JSON
  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      templateId: json['template_id'] is String ? int.parse(json['template_id']) : json['template_id'],
      itemText: json['item_text'] ?? '',
      category: json['category'],
      itemOrder: json['item_order'] is String ? int.parse(json['item_order']) : (json['item_order'] ?? 0),
      isRequired: json['is_required'] == 1 || json['is_required'] == '1' || json['is_required'] == true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'template_id': templateId,
      'item_text': itemText,
      'category': category,
      'item_order': itemOrder,
      'is_required': isRequired ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
