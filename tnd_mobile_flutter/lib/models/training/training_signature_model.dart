class TrainingSignature {
  final int id;
  final int sessionId;
  final String? trainerSignature;
  final String? leaderSignature;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TrainingSignature({
    required this.id,
    required this.sessionId,
    this.trainerSignature,
    this.leaderSignature,
    required this.isCompleted,
    required this.createdAt,
    this.updatedAt,
  });

  factory TrainingSignature.fromJson(Map<String, dynamic> json) {
    return TrainingSignature(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      sessionId: json['session_id'] is String ? int.parse(json['session_id']) : json['session_id'],
      trainerSignature: json['trainer_signature'],
      leaderSignature: json['leader_signature'],
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == '1' || json['is_completed'] == true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'trainer_signature': trainerSignature,
      'leader_signature': leaderSignature,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}