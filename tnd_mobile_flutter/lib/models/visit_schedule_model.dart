/// Visit Schedule Model
/// Scheduled visit to an outlet
class VisitScheduleModel {
  final int id;
  final int outletId;
  final int userId;
  final int templateId;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final String recurrence; // once, daily, weekly, monthly
  final String status; // pending, completed, cancelled
  final String? notes;
  
  // Joined fields
  final String? outletName;
  final String? outletLocation;
  final String? templateName;
  
  final DateTime createdAt;

  VisitScheduleModel({
    required this.id,
    required this.outletId,
    required this.userId,
    required this.templateId,
    required this.scheduledDate,
    this.scheduledTime,
    required this.recurrence,
    required this.status,
    this.notes,
    this.outletName,
    this.outletLocation,
    this.templateName,
    required this.createdAt,
  });

  /// Create from JSON
  factory VisitScheduleModel.fromJson(Map<String, dynamic> json) {
    return VisitScheduleModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      outletId: json['outlet_id'] is String ? int.parse(json['outlet_id']) : json['outlet_id'],
      userId: json['user_id'] is String ? int.parse(json['user_id']) : json['user_id'],
      templateId: json['template_id'] is String ? int.parse(json['template_id']) : json['template_id'],
      scheduledDate: DateTime.parse(json['scheduled_date']),
      scheduledTime: json['scheduled_time'],
      recurrence: json['recurrence'] ?? 'once',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      outletName: json['outlet_name'],
      outletLocation: json['outlet_location'],
      templateName: json['template_name'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'outlet_id': outletId,
      'user_id': userId,
      'template_id': templateId,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0], // Date only
      'scheduled_time': scheduledTime,
      'recurrence': recurrence,
      'notes': notes,
    };
  }

  /// Check if schedule is pending
  bool get isPending => status == 'pending';

  /// Check if schedule is completed
  bool get isCompleted => status == 'completed';

  /// Check if schedule is today
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  /// Check if schedule is overdue
  bool get isOverdue {
    return scheduledDate.isBefore(DateTime.now()) && status == 'pending';
  }

  /// Get recurrence display text
  String get recurrenceText {
    switch (recurrence) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'once':
      default:
        return 'One-time';
    }
  }
}
