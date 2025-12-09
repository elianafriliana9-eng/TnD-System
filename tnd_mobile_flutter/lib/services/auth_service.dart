import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/api_response.dart';
import '../utils/constants.dart';
import 'api_service.dart';

/// Authentication Service
/// Handles user login, logout, and session management
class AuthService {
  final ApiService _apiService = ApiService();

  /// Login user
  Future<ApiResponse<UserModel>> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        AppConstants.endpointLogin,
        body: {
          'email': email,
          'password': password,
        },
        fromJson: (data) => UserModel.fromJson(data),
      );

      if (response.success && response.data != null) {
        await _saveUserSession(response.data!);
      }

      return response;
    } catch (e) {
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Logout user
  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _apiService.post(AppConstants.endpointLogout);
      await _clearUserSession();
      return response;
    } catch (e) {
      await _clearUserSession();
      return ApiResponse.error(message: e.toString());
    }
  }

  /// Save user session to SharedPreferences
  Future<void> _saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyUserId, user.id);
    await prefs.setString(AppConstants.keyUserName, user.name);
    await prefs.setString(AppConstants.keyUserEmail, user.email);
    await prefs.setString(AppConstants.keyUserRole, user.role);
    if (user.divisionId != null) {
      await prefs.setInt(AppConstants.keyUserDivisionId, user.divisionId!);
    }
    if (user.divisionName != null) {
      await prefs.setString(AppConstants.keyUserDivisionName, user.divisionName!);
    }
    if (user.photoPath != null) {
      await prefs.setString(AppConstants.keyUserPhotoPath, user.photoPath!);
    }
    // Save token
    if (user.token != null) {
      await prefs.setString(AppConstants.keyUserToken, user.token!);
      print('Token saved: ${user.token}');
    }
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
  }

  /// Clear user session from SharedPreferences
  Future<void> _clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  /// Get current user from SharedPreferences
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;

    if (!isLoggedIn) return null;

    final userId = prefs.getInt(AppConstants.keyUserId);
    final userName = prefs.getString(AppConstants.keyUserName);
    final userEmail = prefs.getString(AppConstants.keyUserEmail);
    final userRole = prefs.getString(AppConstants.keyUserRole);
    final divisionId = prefs.getInt(AppConstants.keyUserDivisionId);
    final divisionName = prefs.getString(AppConstants.keyUserDivisionName);
    final photoPath = prefs.getString(AppConstants.keyUserPhotoPath);

    if (userId == null || userName == null || userEmail == null || userRole == null) {
      return null;
    }

    return UserModel(
      id: userId,
      name: userName,
      email: userEmail,
      role: userRole,
      divisionId: divisionId,
      divisionName: divisionName,
      photoPath: photoPath,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }
}
