import 'training_checklist_category_model.dart';

class TrainingScheduleModel {
  final int id;
  final int outletId;
  final String outletName;
  final DateTime scheduledDate;
  final String scheduledTime;
  final int? trainerId;
  final String? trainerName;
  final String status; // scheduled, completed, cancelled, expired
  final String? crewLeader;
  final String? crewName; // Nama crew yang sedang ditraining
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<TrainingChecklistCategory>? categories;

  TrainingScheduleModel({
    required this.id,
    required this.outletId,
    required this.outletName,
    required this.scheduledDate,
    required this.scheduledTime,
    this.trainerId,
    this.trainerName,
    required this.status,
    this.crewLeader,
    this.crewName,
    this.createdAt,
    this.updatedAt,
    this.categories,
  });

  factory TrainingScheduleModel.fromJson(Map<String, dynamic> json) {
    return TrainingScheduleModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      outletId: json['outlet_id'] is String
          ? int.parse(json['outlet_id'])
          : json['outlet_id'],
      outletName: json['outlet_name'] ?? '',
      scheduledDate: DateTime.parse(json['scheduled_date']),
      scheduledTime: json['scheduled_time'] ?? '',
      trainerId: json['trainer_id'] != null
          ? (json['trainer_id'] is String
                ? int.parse(json['trainer_id'])
                : json['trainer_id'])
          : null,
      trainerName: json['trainer_name'],
      status: json['status'] ?? 'scheduled',
      crewLeader: json['crew_leader'],
      crewName: json['crew_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      categories: json['categories'] != null
          ? (json['categories'] as List)
                .map(
                  (categoryJson) =>
                      TrainingChecklistCategory.fromJson(categoryJson),
                )
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'outlet_id': outletId,
      'outlet_name': outletName,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'scheduled_time': scheduledTime,
      'trainer_id': trainerId,
      'trainer_name': trainerName,
      'status': status,
      'crew_leader': crewLeader,
      'crew_name': crewName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'categories': categories?.map((category) => category.toJson()).toList(),
    };
  }
}
