import '../constants/api_constants.dart';
import '../constants/app_keys.dart';
import '../utils/logger.dart';
import 'api_service.dart';

/// Service responsible for holding and dynamically fetching API keys and configuration
/// from the backend at runtime so that no sensitive keys are hardcoded in the client app.
class AppConfigService {
  AppConfigService._();
  static final AppConfigService instance = AppConfigService._();

  String? _razorpayKey;
  String? _mapsApiKey;
  String? _supportPhoneNumber;
  String? _supportEmail;
  String? _minAppVersion;
  bool _forceUpdate = false;
  bool _isConfigLoaded = false;

  String? get razorpayKey => _razorpayKey;
  String? get mapsApiKey => _mapsApiKey;
  String? get supportPhoneNumber => _supportPhoneNumber;
  String? get supportEmail => _supportEmail;
  String? get minAppVersion => _minAppVersion;
  bool get forceUpdate => _forceUpdate;
  bool get isConfigLoaded => _isConfigLoaded;

  /// Effective active Razorpay Key: uses backend config key if valid, else falls back to AppKeys.razorpayKeyId
  String get activeRazorpayKey {
    if (_razorpayKey != null &&
        _razorpayKey!.trim().isNotEmpty &&
        !_razorpayKey!.contains('<your_razorpay') &&
        !_razorpayKey!.contains('sample')) {
      return _razorpayKey!.trim();
    }
    return AppKeys.razorpayKeyId;
  }

  /// Effective active Google Maps Key: uses backend config key if valid, else falls back to AppKeys.googleMapsApiKey
  String get activeMapsApiKey {
    if (_mapsApiKey != null &&
        _mapsApiKey!.trim().isNotEmpty &&
        !_mapsApiKey!.contains('sample-maps-key')) {
      return _mapsApiKey!.trim();
    }
    return AppKeys.googleMapsApiKey;
  }

  /// Dynamically update Razorpay key (e.g. from backend checkout/subscription initiate response)
  void setRazorpayKey(String? key) {
    if (key != null && key.isNotEmpty) {
      _razorpayKey = key;
      appLog("🔑 Dynamically updated Razorpay Key from backend: $key");
    }
  }

  /// Dynamically update Maps API key (e.g. from backend config response)
  void setMapsApiKey(String? key) {
    if (key != null && key.isNotEmpty) {
      _mapsApiKey = key;
      appLog("🗺️ Dynamically updated Maps API Key from backend: $key");
    }
  }

  /// Fetch remote configuration and keys from backend (GET /api/public/config)
  Future<void> fetchRemoteConfig() async {
    try {
      appLog("⚙️ Fetching remote app configuration from backend...");
      final response = await ApiService.dio.get(ApiConstants.appConfig);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final payload = data['data'] ?? data['config'] ?? data;
        if (payload is Map<String, dynamic>) {
          if (payload['razorpayKey'] != null || payload['razorpayKeyId'] != null) {
            setRazorpayKey((payload['razorpayKey'] ?? payload['razorpayKeyId'])?.toString());
          }
          if (payload['mapsApiKey'] != null || payload['googleMapsApiKey'] != null) {
            setMapsApiKey((payload['mapsApiKey'] ?? payload['googleMapsApiKey'])?.toString());
          }
          if (payload['supportPhoneNumber'] != null) {
            _supportPhoneNumber = payload['supportPhoneNumber']?.toString();
          }
          if (payload['supportEmail'] != null) {
            _supportEmail = payload['supportEmail']?.toString();
          }
          if (payload['minAppVersion'] != null) {
            _minAppVersion = payload['minAppVersion']?.toString();
          }
          if (payload['forceUpdate'] != null && payload['forceUpdate'] is bool) {
            _forceUpdate = payload['forceUpdate'] as bool;
          }
        }
      }
      _isConfigLoaded = true;
      appLog("✅ Remote app configuration successfully loaded.");
    } catch (e) {
      appLog("⚙️ Remote config endpoint fallback: $e. Will rely on transaction-level payload keys.");
    }
  }
}
