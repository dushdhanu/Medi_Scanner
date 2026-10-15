import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyService {
  static const String _keyPrefKey = 'gemini_api_key';

  // Default fallback key (can be populated by the developer or user in-app)
  static const String defaultKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Get the active API key (from local storage if saved, otherwise default)
  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_keyPrefKey);
    if (savedKey != null && savedKey.trim().isNotEmpty) {
      return savedKey.trim();
    }
    return defaultKey.trim();
  }

  /// Check whether an API key is available
  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key.isNotEmpty;
  }

  /// Save an API key to local storage
  static Future<bool> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_keyPrefKey, key.trim());
  }

  /// Remove the stored API key
  static Future<bool> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_keyPrefKey);
  }
}
