import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/api_config_manager.dart';
import '../utils/response_utils.dart';
import '../models/api_response.dart';

/// User Service
/// Handles user profile operations
class UserService {
  /// Upload profile photo
  Future<ApiResponse<String>> uploadProfilePhoto(File photo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyUserToken);

      if (token == null) {
        return ApiResponse.error(message: 'Token not found. Please login again.');
      }

      // Get dynamic API URL
      final apiUrl = await ApiConfigManager.getApiUrl();
      final uri = Uri.parse('$apiUrl/profile-photo-upload.php');
      var request = http.MultipartRequest('POST', uri);
      
      // Add Authorization header
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add photo file
      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Profile photo upload response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Clean the response body to handle PHP warnings
        String cleanBody = ResponseUtils.cleanResponseBody(response.body);
        
        final Map<String, dynamic> jsonResponse = json.decode(cleanBody);
        
        if (jsonResponse['success'] == true) {
          final photoUrl = jsonResponse['data']['photo_url'] as String;
          
          // Update photo path in SharedPreferences
          final photoPath = jsonResponse['data']['photo_path'] as String;
          await prefs.setString(AppConstants.keyUserPhotoPath, photoPath);
          
          return ApiResponse.success(data: photoUrl);
        } else {
          return ApiResponse.error(
            message: jsonResponse['message'] ?? 'Failed to upload photo',
          );
        }
      } else {
        return ApiResponse.error(
          message: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error uploading profile photo: $e');
      return ApiResponse.error(message: 'Error uploading photo: $e');
    }
  }
}
