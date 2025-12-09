import 'constants.dart';

/// API Configuration Manager
/// Handles dynamic API configuration including base URLs
class ApiConfigManager {
  /// Get the base URL for API calls
  static Future<String> getBaseUrl() async {
    return AppConstants.baseUrl;
  }

  /// Get the API URL endpoint
  static Future<String> getApiUrl() async {
    return AppConstants.apiBaseUrl;
  }
}