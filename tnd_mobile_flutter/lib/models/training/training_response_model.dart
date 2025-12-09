class TrainingResponse {
  final int id;
  final int sessionId;
  final int itemId;
  final String responseType; // 'check', 'x', or 'n/a'
  final String? trainerComment;
  final String? leaderComment;
  final List<String> photoPaths;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isRevised;

  TrainingResponse({
    required this.id,
    required this.sessionId,
    required this.itemId,
    required this.responseType,
    this.trainerComment,
    this.leaderComment,
    required this.photoPaths,
    required this.createdAt,
    this.updatedAt,
    this.isRevised = false,
  });

  factory TrainingResponse.fromJson(Map<String, dynamic> json) {
    return TrainingResponse(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      sessionId: json['session_id'] is String ? int.parse(json['session_id']) : json['session_id'],
      itemId: json['item_id'] is String ? int.parse(json['item_id']) : json['item_id'],
      responseType: json['response_type'] ?? 'n/a',
      trainerComment: json['trainer_comment'],
      leaderComment: json['leader_comment'],
      photoPaths: (json['photo_paths'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isRevised: json['is_revised'] == 1 || json['is_revised'] == '1' || json['is_revised'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'item_id': itemId,
      'response_type': responseType,
      'trainer_comment': trainerComment,
      'leader_comment': leaderComment,
      'photo_paths': photoPaths,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_revised': isRevised ? 1 : 0,
    };
  }
}