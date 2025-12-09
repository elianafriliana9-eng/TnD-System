import '../models/outlet_model.dart';
import '../models/api_response.dart';
import '../utils/constants.dart';
import 'api_service.dart';

/// Outlet Service
/// Handles outlet CRUD operations
class OutletService {
  final ApiService _apiService = ApiService();

  /// Get all outlets (with optional division filter)
  Future<ApiResponse<List<OutletModel>>> getOutlets({int? divisionId, int? limit}) async {
    try {
      String endpoint = AppConstants.endpointOutlets;
      List<String> params = [];

      if (divisionId != null) {
        params.add('division_id=$divisionId');
      }

      // Handle limit parameter
      if (limit != null && limit < 0) {
        // Negative limit means "get all"
        params.add('limit=-1');
      } else if (limit != null && limit > 0) {
        // Positive limit - use as-is
        params.add('limit=$limit');
      } else {
        // No limit specified - default to get all
        params.add('limit=-1');
      }

      if (params.isNotEmpty) {
        endpoint += '?' + params.join('&');
      }

      final response = await _apiService.get(
        endpoint,
        fromJson: (data) {
          // Backend returns {data: [...], pagination: {...}}
          // Extract the 'data' array
          if (data is Map && data['data'] is List) {
            return (data['data'] as List)
                .map((item) => OutletModel.fromJson(item))
                .toList();
          } else if (data is List) {
            return data.map((item) => OutletModel.fromJson(item)).toList();
          }
          return <OutletModel>[];
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Create new outlet
  Future<ApiResponse<OutletModel>> createOutlet(OutletModel outlet) async {
    try {
      final response = await _apiService.post(
        AppConstants.endpointOutletsCreate,
        body: outlet.toApiJson(),
        fromJson: (data) => OutletModel.fromJson(data),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Update outlet
  Future<ApiResponse<OutletModel>> updateOutlet(int id, OutletModel outlet) async {
    try {
      final body = outlet.toApiJson();
      body['id'] = id;

      final response = await _apiService.post(
        AppConstants.endpointOutletsUpdate,
        body: body,
        fromJson: (data) => OutletModel.fromJson(data),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Delete outlet
  Future<ApiResponse<void>> deleteOutlet(int id) async {
    try {
      final response = await _apiService.post(
        AppConstants.endpointOutletsDelete,
        body: {'id': id},
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }
}
