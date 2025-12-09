/// Application Constants
/// TND System Mobile App
class AppConstants {
  static const String keyUserToken = 'user_token';
  // API Configuration
  // NOTE: For different environments:
  // - Android Emulator: use 10.0.2.2 instead of localhost
  // - iOS Simulator: use localhost
  // - Physical Device: use computer's IP address
  static const String apiBaseUrl = 'https://tndsystem.online/backend-web/api';
  static const String baseUrl = 'https://tndsystem.online/backend-web';

  // App Info
  static const String appName = 'TND System';
  static const String appVersion = '1.0.0';

  // SharedPreferences Keys
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserRole = 'user_role';
  static const String keyUserDivisionId = 'user_division_id';
  static const String keyUserDivisionName = 'user_division_name';
  static const String keyUserPhotoPath = 'user_photo_path';
  static const String keyIsLoggedIn = 'is_logged_in';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleSupervisor = 'supervisor';
  static const String roleTrainer = 'trainer';
  static const String roleStaff = 'staff';

  // API Endpoints
  static const String endpointLogin = '/login.php';
  static const String endpointLogout = '/logout.php';
  static const String endpointUsers = '/users-simple.php';
  static const String endpointDivisions = '/divisions.php';
  static const String endpointOutlets = '/outlets.php';
  static const String endpointOutletsCreate = '/outlets-create.php';
  static const String endpointOutletsUpdate = '/outlet-update.php';
  static const String endpointOutletsDelete = '/outlet-delete.php';

  // Visit Endpoints
  static const String endpointChecklistTemplates = '/checklist-templates.php';
  static const String endpointVisits = '/visits.php';
  static const String endpointVisitsCreate = '/visits-create.php';
  static const String endpointVisitComplete = '/visit-complete.php';
  static const String endpointVisitChecklistResponse =
      '/visit-checklist-response.php';
  static const String endpointVisitPhotoUpload = '/visit-photo-upload.php';
  static const String endpointVisitSchedules = '/visit-schedules.php';
  static const String endpointVisitSchedulesCreate =
      '/visit-schedules-create.php';
  static const String endpointVisitSchedulesDelete =
      '/visit-schedules-delete.php';
  static const String endpointVisitResponses = '/visit-responses.php';
  static const String endpointVisitCheckToday = '/visit-check-today.php';
  static const String endpointVisitDetail = '/visit-detail.php';
}
