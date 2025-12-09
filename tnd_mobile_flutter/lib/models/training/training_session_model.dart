class TrainingSessionModel {
  final int id;
  final int scheduleId;
  final int outletId;
  final String outletName;
  final DateTime sessionDate;
  final int? trainerId;
  final String? trainerName;
  final String? crewLeaderId;
  final String? crewLeaderName;
  final String? crewName; // Nama crew yang sedang ditraining
  final String status; // started, completed, cancelled
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? revisionNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TrainingSessionModel({
    required this.id,
    required this.scheduleId,
    required this.outletId,
    required this.outletName,
    required this.sessionDate,
    this.trainerId,
    this.trainerName,
    this.crewLeaderId,
    this.crewLeaderName,
    this.crewName,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.revisionNotes,
    required this.createdAt,
    this.updatedAt,
  });

  factory TrainingSessionModel.fromJson(Map<String, dynamic> json) {
    return TrainingSessionModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      scheduleId: json['schedule_id'] is String
          ? int.parse(json['schedule_id'])
          : json['schedule_id'],
      outletId: json['outlet_id'] is String
          ? int.parse(json['outlet_id'])
          : json['outlet_id'],
      outletName: json['outlet_name'] ?? '',
      sessionDate: DateTime.parse(json['session_date']),
      trainerId: json['trainer_id'] != null
          ? (json['trainer_id'] is String
                ? int.parse(json['trainer_id'])
                : json['trainer_id'])
          : null,
      trainerName: json['trainer_name'],
      crewLeaderId: json['crew_leader_id'] != null
          ? (json['crew_leader_id'] is String
                ? int.parse(json['crew_leader_id'])
                : json['crew_leader_id'])
          : null,
      crewLeaderName: json['crew_leader_name'],
      crewName: json['crew_name'],
      status: json['status'] ?? 'started',
      startedAt: DateTime.parse(
        json['started_at'] ?? DateTime.now().toIso8601String(),
      ),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      revisionNotes: json['revision_notes'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'outlet_id': outletId,
      'outlet_name': outletName,
      'session_date': sessionDate.toIso8601String().split('T')[0],
      'trainer_id': trainerId,
      'trainer_name': trainerName,
      'crew_leader_id': crewLeaderId,
      'crew_leader_name': crewLeaderName,
      'crew_name': crewName,
      'status': status,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'revision_notes': revisionNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
