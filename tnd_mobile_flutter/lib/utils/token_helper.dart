import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Helper to get token from SharedPreferences
class TokenHelper {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyUserToken);
  }
}
