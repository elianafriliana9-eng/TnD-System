import '../models/division_model.dart';
import '../models/api_response.dart';
import '../utils/constants.dart';
import 'api_service.dart';

/// Division Service
/// Handles division-related operations
class DivisionService {
  final ApiService _apiService = ApiService();

  /// Get all divisions
  Future<ApiResponse<List<DivisionModel>>> getDivisions() async {
    try {
      final response = await _apiService.get(
        '${AppConstants.endpointDivisions}?simple=true',
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => DivisionModel.fromJson(item)).toList();
          }
          return <DivisionModel>[];
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }
}
