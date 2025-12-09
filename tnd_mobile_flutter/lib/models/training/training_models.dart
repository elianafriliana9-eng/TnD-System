// Training Models Export
// Central export file for all training-related models

export 'trainer_model.dart';
export 'training_schedule_model.dart';
export 'training_checklist_category_model.dart';
export 'training_checklist_item_model.dart';
export 'training_session_model.dart';
export 'training_response_model.dart';
export 'training_signature_model.dart';

/// Training History Model
class TrainingHistory {
  final int id;
  final int sessionId;
  final String outletName;
  final DateTime sessionDate;
  final String? trainerName;
  final String? notes;
  final String status;
  final DateTime? completedAt;

  TrainingHistory({
    required this.id,
    required this.sessionId,
    required this.outletName,
    required this.sessionDate,
    this.trainerName,
    this.notes,
    required this.status,
    this.completedAt,
  });

  factory TrainingHistory.fromJson(Map<String, dynamic> json) {
    return TrainingHistory(
      id: json['id'] ?? 0,
      sessionId: json['session_id'] ?? 0,
      outletName: json['outlet_name'] ?? 'Unknown',
      sessionDate: json['session_date'] is String
          ? DateTime.parse(json['session_date'])
          : DateTime.now(),
      trainerName: json['trainer_name'],
      notes: json['notes'],
      status: json['status'] ?? 'completed',
      completedAt: json['completed_at'] is String
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'outlet_name': outletName,
      'session_date': sessionDate.toIso8601String(),
      'trainer_name': trainerName,
      'notes': notes,
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}