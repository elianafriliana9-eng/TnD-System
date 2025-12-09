import '../models/visit_schedule_model.dart';
import '../models/api_response.dart';
import '../utils/constants.dart';
import 'api_service.dart';

/// Visit Schedule Service
/// Handles visit schedule operations
class VisitScheduleService {
  final ApiService _apiService = ApiService();

  /// Get all schedules
  Future<ApiResponse<List<VisitScheduleModel>>> getSchedules({String? status}) async {
    try {
      String endpoint = AppConstants.endpointVisitSchedules;
      if (status != null) {
        endpoint += '?status=$status';
      }

      final response = await _apiService.get(
        endpoint,
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => VisitScheduleModel.fromJson(item)).toList();
          }
          return <VisitScheduleModel>[];
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Get schedules by date range
  Future<ApiResponse<List<VisitScheduleModel>>> getSchedulesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];
      
      final response = await _apiService.get(
        '${AppConstants.endpointVisitSchedules}?start_date=$startDateStr&end_date=$endDateStr',
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => VisitScheduleModel.fromJson(item)).toList();
          }
          return <VisitScheduleModel>[];
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Create new schedule
  Future<ApiResponse<Map<String, dynamic>>> createSchedule({
    required int outletId,
    required int templateId,
    required DateTime scheduledDate,
    String? scheduledTime,
    String recurrence = 'once',
    String? notes,
  }) async {
    try {
      final response = await _apiService.post(
        AppConstants.endpointVisitSchedulesCreate,
        body: {
          'outlet_id': outletId,
          'template_id': templateId,
          'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
          'scheduled_time': scheduledTime,
          'recurrence': recurrence,
          'notes': notes,
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Delete schedule
  Future<ApiResponse<void>> deleteSchedule(int id) async {
    try {
      final response = await _apiService.post(
        AppConstants.endpointVisitSchedulesDelete,
        body: {'id': id},
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }
}
