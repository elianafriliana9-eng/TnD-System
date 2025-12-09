import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visit_model.dart';
import '../models/api_response.dart';
import '../utils/constants.dart';
import '../utils/api_config_manager.dart';
import '../utils/response_utils.dart';
import 'api_service.dart';

/// Visit Service
/// Handles visit operations
class VisitService {
  final ApiService _apiService = ApiService();

  /// Get all visits for current user
  Future<ApiResponse<List<VisitModel>>> getVisits() async {
    try {
      final response = await _apiService.get(
        AppConstants.endpointVisits,
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => VisitModel.fromJson(item)).toList();
          }
          return <VisitModel>[];
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Get visit by ID with details (responses and photos)
  Future<ApiResponse<VisitModel>> getVisitById(int id) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.endpointVisitDetail}?visit_id=$id',
        fromJson: (data) {
          print('🔍 Raw visit detail response: $data');
          
          // visit-detail.php returns {visit: {...}, responses: [...], photos: [...]}
          // We need to merge them for VisitModel
          if (data is Map<String, dynamic>) {
            final visitData = Map<String, dynamic>.from(data['visit'] ?? {});
            
            print('📦 Visit data before merge: $visitData');
            print('💰 Financial fields from API:');
            print('  - uang_omset_modal: ${visitData['uang_omset_modal']}');
            print('  - uang_ditukar: ${visitData['uang_ditukar']}');
            print('  - cash: ${visitData['cash']}');
            print('  - qris: ${visitData['qris']}');
            print('  - debit_kredit: ${visitData['debit_kredit']}');
            print('  - total: ${visitData['total']}');
            print('  - kategoric: ${visitData['kategoric']}');
            print('  - leadtime: ${visitData['leadtime']}');
            print('  - status_keuangan: ${visitData['status_keuangan']}');
            print('  - crew_in_charge: ${visitData['crew_in_charge']}');
            
            visitData['responses'] = data['responses'];
            visitData['photos'] = data['photos'];
            return VisitModel.fromJson(visitData);
          }
          throw Exception('Invalid data format');
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Get visits by outlet
  Future<ApiResponse<List<VisitModel>>> getVisitsByOutlet(int outletId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.endpointVisits}?outlet_id=$outletId',
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => VisitModel.fromJson(item)).toList();
          }
          return <VisitModel>[];
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Create new visit (template-based removed, now category-based)
  Future<ApiResponse<VisitModel>> createVisit({
    required int outletId,
    String? notes,
    String? crewInCharge,
  }) async {
    try {
      print('🚀 Creating visit with:');
      print('   - outletId: $outletId');
      print('   - notes: $notes');
      print('   - crewInCharge: $crewInCharge');
      
      final response = await _apiService.post(
        AppConstants.endpointVisitsCreate,
        body: {
          'outlet_id': outletId,
          'notes': notes,
          if (crewInCharge != null) 'crew_in_charge': crewInCharge,
        },
        fromJson: (data) => VisitModel.fromJson(data),
      );

      if (response.success && response.data != null) {
        print('✅ Visit created successfully');
        print('   - Visit ID: ${response.data!.id}');
        print('   - Crew in returned data: ${response.data!.crewInCharge}');
      }

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Save checklist response
  Future<ApiResponse<void>> saveChecklistResponse({
    required int visitId,
    required int checklistItemId,
    required String response, // 'ok', 'not_ok', 'na'
    String? notes,
  }) async {
    try {
      final apiResponse = await _apiService.post(
        AppConstants.endpointVisitChecklistResponse,
        body: {
          'visit_id': visitId,
          'checklist_item_id': checklistItemId,
          'response': response,
          'notes': notes,
        },
      );

      return apiResponse;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Upload visit photo
  Future<ApiResponse<Map<String, dynamic>>> uploadPhoto({
    required int visitId,
    required File photoFile,
    int? checklistItemId,
    String? description,
  }) async {
    try {
      // Get dynamic API URL
      final apiUrl = await ApiConfigManager.getApiUrl();
      final url = Uri.parse('$apiUrl${AppConstants.endpointVisitPhotoUpload}');
      
      print('🌐 API URL: $apiUrl');
      print('📤 Full upload URL: $url');
      
      // Get token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyUserToken);
      
      var request = http.MultipartRequest('POST', url);
      
      // Add authorization header
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
        print('Adding token to upload request: Bearer ${token.substring(0, 10)}...');
      }
      
      request.fields['visit_id'] = visitId.toString();
      if (checklistItemId != null) {
        request.fields['checklist_item_id'] = checklistItemId.toString();
      }
      if (description != null) {
        request.fields['description'] = description;
      }

      request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));

      print('Uploading photo for visit $visitId, item $checklistItemId');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload Photo Status: ${response.statusCode}');
      print('Upload Photo Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Clean the response body to handle PHP warnings
        String cleanBody = ResponseUtils.cleanResponseBody(response.body);
        
        final jsonResponse = jsonDecode(cleanBody);
        if (jsonResponse['success'] == true) {
          return ApiResponse.success(
            data: jsonResponse['data'],
            message: jsonResponse['message'],
          );
        } else {
          return ApiResponse.error(message: jsonResponse['message'] ?? 'Upload failed');
        }
      } else {
        return ApiResponse.error(message: 'Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('Upload Photo Error: $e');
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Complete visit
  Future<ApiResponse<VisitModel>> completeVisit({
    required int visitId,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post(
        AppConstants.endpointVisitComplete,
        body: {
          'visit_id': visitId,
          'notes': notes,
        },
        fromJson: (data) => VisitModel.fromJson(data),
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Get visit checklist responses with details
  Future<ApiResponse<List<Map<String, dynamic>>>> getVisitResponses(int visitId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.endpointVisitResponses}?visit_id=$visitId',
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => item as Map<String, dynamic>).toList();
          }
          return <Map<String, dynamic>>[];
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Check if outlet has been visited today
  Future<ApiResponse<bool>> hasVisitedToday(int outletId) async {
    try {
      final response = await _apiService.get(
        '${AppConstants.endpointVisitCheckToday}?outlet_id=$outletId',
        fromJson: (data) {
          if (data is Map<String, dynamic>) {
            return data['has_visited'] == true;
          }
          return false;
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Update financial and assessment data
  Future<bool> updateFinancialAssessment(Map<String, dynamic> data) async {
    try {
      print('📊 Updating financial assessment with data: $data');
      
      final response = await _apiService.post(
        '/visit-update-financial.php',
        body: data,
        fromJson: (responseData) => responseData,
      );

      print('📊 Update response: success=${response.success}, message=${response.message}');
      
      if (!response.success && response.message != null) {
        print('❌ Update failed: ${response.message}');
      }
      
      return response.success;
    } catch (e) {
      print('❌ Error updating financial assessment: $e');
      return false;
    }
  }

  /// Get improvement recommendations (NOK findings with photos)
  Future<ApiResponse<List<Map<String, dynamic>>>> getRecommendations(int visitId) async {
    try {
      print('📝 Loading recommendations for visit: $visitId');
      
      final response = await _apiService.get(
        '/improvement-recommendations.php?visit_id=$visitId',
        fromJson: (data) {
          if (data is Map && data['findings'] is List) {
            return (data['findings'] as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          }
          return <Map<String, dynamic>>[];
        },
      );

      return response;
    } catch (e) {
      print('❌ Error loading recommendations: $e');
      return ApiResponse.error(message: e.toString());
    }
  }
}
