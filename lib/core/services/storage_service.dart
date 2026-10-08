import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static SharedPreferencesService? _instance;
  static SharedPreferences? _preferences;
  static Future<SharedPreferencesService>? _initFuture;

  /// Initializes SharedPreferences once at app startup
  static Future<SharedPreferencesService> init() async {
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
      _instance = SharedPreferencesService();
    }
    return _instance!;
  }

  /// Thread-safe singleton accessor that ensures _preferences is fully ready before returning
  static Future<SharedPreferencesService> getInstance() async {
    if (_instance != null && _preferences != null) {
      return _instance!;
    }
    _initFuture ??= () async {
      _preferences = await SharedPreferences.getInstance();
      _instance = SharedPreferencesService();
      return _instance!;
    }();
    return _initFuture!;
  }

  // Setters with null-safety protection
  Future<bool> setBool(String key, bool value) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    return prefs.setBool(key, value);
  }

  Future<bool> setInt(String key, int value) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    return prefs.setInt(key, value);
  }

  Future<bool> setDouble(String key, double value) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    return prefs.setDouble(key, value);
  }

  Future<bool> setString(String key, String value) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    return prefs.setStringList(key, value);
  }

  // Getters with null-safety protection
  bool? getBool(String key) {
    return _preferences?.getBool(key);
  }

  int? getInt(String key) {
    return _preferences?.getInt(key);
  }

  double? getDouble(String key) {
    return _preferences?.getDouble(key);
  }

  String? getString(String key) {
    return _preferences?.getString(key);
  }

  List<String>? getStringList(String key) {
    return _preferences?.getStringList(key);
  }

  // Remove
  Future<bool> remove(String key) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    return prefs.remove(key);
  }

  // Clear all data
  Future<bool> clear() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    return prefs.clear();
  }

  // Get all keys
  Set<String> getKeys() {
    return _preferences?.getKeys() ?? <String>{};
  }
}
