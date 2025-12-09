import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/response_utils.dart';

import '../models/api_response.dart';

/// API Service
/// Handles all HTTP requests to the backend
class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // Use production URL from constants
  static const String _baseUrl = AppConstants.apiBaseUrl;

  /// Get authentication headers with token
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyUserToken);
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('Adding token to request: Bearer ${token.substring(0, 10)}...');
    } else {
      print('Warning: No token found in storage');
    }
    
    return headers;
  }

  /// Make GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    bool isFullUrl = false,
  }) async {
    try {
      final url = Uri.parse(isFullUrl ? endpoint : '$_baseUrl$endpoint');
      print('GET Request: $url');

      final authHeaders = await _getAuthHeaders();
      final response = await http.get(
        url,
        headers: {
          ...authHeaders,
          ...?headers,
        },
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request timeout - Server tidak merespon dalam 60 detik');
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('GET Error: $e');
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Make POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    bool isFullUrl = false,
  }) async {
    try {
      final url = Uri.parse(isFullUrl ? endpoint : '$_baseUrl$endpoint');
      print('POST Request: $url');
      print('POST Body: $body');

      final authHeaders = await _getAuthHeaders();
      final response = await http.post(
        url,
        headers: {
          ...authHeaders,
          ...?headers,
        },
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request timeout - Server tidak merespon dalam 60 detik');
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('POST Error: $e');
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Make PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    bool isFullUrl = false,
  }) async {
    try {
      final url = Uri.parse(isFullUrl ? endpoint : '$_baseUrl$endpoint');
      print('PUT Request: $url');
      print('PUT Body: $body');

      final authHeaders = await _getAuthHeaders();
      final response = await http.put(
        url,
        headers: {
          ...authHeaders,
          ...?headers,
        },
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('PUT Error: $e');
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Make DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    bool isFullUrl = false,
  }) async {
    try {
      final url = Uri.parse(isFullUrl ? endpoint : '$_baseUrl$endpoint');
      print('DELETE Request URL: $url');

      final authHeaders = await _getAuthHeaders();
      print('DELETE Auth Headers: $authHeaders');
      print('DELETE Custom Headers: $headers');
      
      final mergedHeaders = {
        ...authHeaders,
        ...?headers,
      };
      print('DELETE Merged Headers: $mergedHeaders');

      final response = await http.delete(
        url,
        headers: mergedHeaders,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('DELETE Response Status Code: ${response.statusCode}');
      print('DELETE Response Headers: ${response.headers}');
      print('DELETE Response Body (raw): ${response.bodyBytes}');
      print('DELETE Response Body (string): ${response.body}');

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      print('DELETE Error - Exception: $e');
      print('DELETE Error - Exception Type: ${e.runtimeType}');
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Handle HTTP response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    try {
      print('_handleResponse: statusCode = ${response.statusCode}');
      print('_handleResponse: raw body = ${response.body}');
      
      // Clean the response body to remove any PHP warnings/HTML before JSON
      String cleanBody = ResponseUtils.cleanResponseBody(response.body);
      print('_handleResponse: cleaned body = $cleanBody');
      
      final jsonResponse = jsonDecode(cleanBody);
      print('_handleResponse: decoded JSON = $jsonResponse');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('_handleResponse: success status code, creating ApiResponse');
        return ApiResponse<T>.fromJson(jsonResponse, fromJson);
      } else {
        print('_handleResponse: error status code ${response.statusCode}');
        return ApiResponse.error(
          message: jsonResponse['message'] ?? 'Request failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('_handleResponse: Exception caught: $e');
      print('_handleResponse: Exception type: ${e.runtimeType}');
      return ApiResponse.error(
        message: 'Failed to parse response: $e',
        statusCode: response.statusCode,
      );
    }
  }
}
