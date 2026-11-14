import '../constants/app_keys.dart';
import '../constants/app_routes.dart';
import '../router/app_router.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';

class SessionManager {
  static bool _isLoggingOut = false;

  static Future<void> forceLogout() async {
    if (_isLoggingOut) return;

    _isLoggingOut = true;

    appLog("🚪 Force logout triggered");

    try {
      final prefs = await SharedPreferencesService.getInstance();
      await prefs.remove(AppKeys.accessToken);
      await prefs.remove(AppKeys.refreshToken);
      await prefs.remove(AppKeys.user);
    } catch (e) {
      appLog("Error clearing auth tokens on force logout: $e");
    } finally {
      _isLoggingOut = false;
    }

    try {
      AppRouter.router.go(AppRoutes.login);
    } catch (e) {
      appLog("Router navigation notice on force logout: $e");
    }
  }
}
