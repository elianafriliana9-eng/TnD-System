/// Visit Model
/// Represents a visit to an outlet
class VisitModel {
  final int id;
  final int outletId;
  final int userId;
  final int? templateId; // Nullable - template not required anymore
  final DateTime visitDate;
  final String status; // scheduled, in_progress, completed, cancelled
  final String? notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? checkInTime; // Time format: HH:mm:ss
  final String? checkOutTime; // Time format: HH:mm:ss
  
  // Financial data
  final double? uangOmsetModal;
  final double? uangDitukar;
  final double? cash;
  final double? qris;
  final double? debitKredit;
  final double? total; // Auto-calculated in backend
  
  // Assessment data
  final String? kategoric; // minor, major, ZT
  final int? leadtime; // in minutes
  final String? statusKeuangan; // open, close
  final String? crewInCharge;
  
  // Joined fields
  final String? outletName;
  final String? outletLocation;
  final String? userName;
  final String? templateName;
  
  // Related data
  final List<ChecklistResponseModel>? responses;
  final List<VisitPhotoModel>? photos;

  VisitModel({
    required this.id,
    required this.outletId,
    required this.userId,
    this.templateId,
    required this.visitDate,
    required this.status,
    this.notes,
    this.startedAt,
    this.completedAt,
    this.checkInTime,
    this.checkOutTime,
    this.uangOmsetModal,
    this.uangDitukar,
    this.cash,
    this.qris,
    this.debitKredit,
    this.total,
    this.kategoric,
    this.leadtime,
    this.statusKeuangan,
    this.crewInCharge,
    this.outletName,
    this.outletLocation,
    this.userName,
    this.templateName,
    this.responses,
    this.photos,
  });

  /// Create from JSON
  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      outletId: json['outlet_id'] is String ? int.parse(json['outlet_id']) : json['outlet_id'],
      userId: json['user_id'] is String ? int.parse(json['user_id']) : json['user_id'],
      templateId: json['template_id'] != null
          ? (json['template_id'] is String ? int.parse(json['template_id']) : json['template_id'])
          : null,
      visitDate: DateTime.parse(json['visit_date']),
      status: json['status'] ?? 'scheduled',
      notes: json['notes'],
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      // Financial data
      uangOmsetModal: json['uang_omset_modal'] != null ? double.parse(json['uang_omset_modal'].toString()) : null,
      uangDitukar: json['uang_ditukar'] != null ? double.parse(json['uang_ditukar'].toString()) : null,
      cash: json['cash'] != null ? double.parse(json['cash'].toString()) : null,
      qris: json['qris'] != null ? double.parse(json['qris'].toString()) : null,
      debitKredit: json['debit_kredit'] != null ? double.parse(json['debit_kredit'].toString()) : null,
      total: json['total'] != null ? double.parse(json['total'].toString()) : null,
      // Assessment data
      kategoric: json['kategoric'],
      leadtime: json['leadtime'] != null ? int.parse(json['leadtime'].toString()) : null,
      statusKeuangan: json['status_keuangan'],
      crewInCharge: json['crew_in_charge'],
      // Joined fields
      outletName: json['outlet_name'],
      outletLocation: json['outlet_location'],
      userName: json['user_name'],
      templateName: json['template_name'],
      responses: json['responses'] != null
          ? (json['responses'] as List).map((r) => ChecklistResponseModel.fromJson(r)).toList()
          : null,
      photos: json['photos'] != null
          ? (json['photos'] as List).map((p) => VisitPhotoModel.fromJson(p)).toList()
          : null,
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'outlet_id': outletId,
      'user_id': userId,
      if (templateId != null) 'template_id': templateId,
      'visit_date': visitDate.toIso8601String(),
      'status': status,
      'notes': notes,
      if (crewInCharge != null) 'crew_in_charge': crewInCharge,
    };
  }

  /// Check if visit is completed
  bool get isCompleted => status == 'completed';

  /// Check if visit is in progress
  bool get isInProgress => status == 'in_progress';

  /// Get completion percentage
  double getCompletionPercentage(int totalItems) {
    if (responses == null || responses!.isEmpty || totalItems == 0) {
      return 0.0;
    }
    return (responses!.length / totalItems) * 100;
  }
}

/// Checklist Response Model
/// User's response to a checklist item during visit
class ChecklistResponseModel {
  final int id;
  final int visitId;
  final int checklistItemId;
  final String response; // ok, not_ok, na
  final String? notes;
  final String? itemText;
  final DateTime createdAt;

  ChecklistResponseModel({
    required this.id,
    required this.visitId,
    required this.checklistItemId,
    required this.response,
    this.notes,
    this.itemText,
    required this.createdAt,
  });

  /// Create from JSON
  factory ChecklistResponseModel.fromJson(Map<String, dynamic> json) {
    return ChecklistResponseModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      visitId: json['visit_id'] is String ? int.parse(json['visit_id']) : json['visit_id'],
      // API returns 'checklist_point_id', fallback to 'checklist_item_id' for compatibility
      checklistItemId: (json['checklist_point_id'] ?? json['checklist_item_id']) is String 
          ? int.parse((json['checklist_point_id'] ?? json['checklist_item_id']).toString()) 
          : (json['checklist_point_id'] ?? json['checklist_item_id']),
      response: json['response'] ?? 'na',
      notes: json['notes'],
      itemText: json['item_text'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'visit_id': visitId,
      'checklist_item_id': checklistItemId,
      'response': response,
      'notes': notes,
    };
  }

  /// Get response icon
  String get responseIcon {
    switch (response) {
      case 'ok':
        return '✓';
      case 'not_ok':
        return '✗';
      case 'na':
        return 'N/A';
      default:
        return '-';
    }
  }

  /// Get response color
  String get responseType {
    switch (response) {
      case 'ok':
        return 'success';
      case 'not_ok':
        return 'danger';
      case 'na':
        return 'secondary';
      default:
        return 'secondary';
    }
  }
}

/// Visit Photo Model
/// Photo uploaded during visit
class VisitPhotoModel {
  final int id;
  final int visitId;
  final int? checklistItemId;
  final String photoPath;
  final String? description;
  final String? itemText;
  final DateTime uploadedAt;

  VisitPhotoModel({
    required this.id,
    required this.visitId,
    this.checklistItemId,
    required this.photoPath,
    this.description,
    this.itemText,
    required this.uploadedAt,
  });

  /// Create from JSON
  factory VisitPhotoModel.fromJson(Map<String, dynamic> json) {
    return VisitPhotoModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      visitId: json['visit_id'] is String ? int.parse(json['visit_id']) : json['visit_id'],
      checklistItemId: json['checklist_item_id'] != null
          ? (json['checklist_item_id'] is String ? int.parse(json['checklist_item_id']) : json['checklist_item_id'])
          : null,
      photoPath: json['photo_path'] ?? '',
      description: json['description'],
      itemText: json['item_text'],
      uploadedAt: DateTime.parse(json['uploaded_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Get full photo URL
  String getPhotoUrl(String baseUrl) {
    return '$baseUrl/$photoPath';
  }
}
