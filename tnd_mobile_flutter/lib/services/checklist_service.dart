import '../models/checklist_model.dart';
import '../models/api_response.dart';
import '../utils/constants.dart';
import 'api_service.dart';

/// Checklist Service
/// Handles checklist template operations
class ChecklistService {
  final ApiService _apiService = ApiService();

  /// Get all checklist templates
  Future<ApiResponse<List<ChecklistTemplateModel>>> getTemplates() async {
    try {
      final response = await _apiService.get(
        AppConstants.endpointChecklistTemplates,
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => ChecklistTemplateModel.fromJson(item)).toList();
          }
          return <ChecklistTemplateModel>[];
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Get template with items by ID
  Future<ApiResponse<ChecklistTemplateModel>> getTemplateById(int id) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.endpointChecklistTemplates}?id=$id',
        fromJson: (data) => ChecklistTemplateModel.fromJson(data),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }
}
