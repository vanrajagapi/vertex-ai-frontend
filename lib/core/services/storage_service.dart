import 'package:get_storage/get_storage.dart';

class StorageService {
  static final GetStorage _storage = GetStorage();

  static const String _tokenKey = 'access_token';
  static const String _userDataKey = 'user_data';
  static const String _baseUrlKey = 'api_base_url';

  static Future<void> saveToken(String token) async {
    await _storage.write(_tokenKey, token);
  }

  static String? getToken() {
    return _storage.read(_tokenKey);
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(_userDataKey, userData);
  }

  static Map<String, dynamic>? getUserData() {
    return _storage.read(_userDataKey);
  }

  static Future<void> saveBaseUrl(String url) async {
    await _storage.write(_baseUrlKey, url);
  }

  static String? getBaseUrl() {
    return _storage.read(_baseUrlKey);
  }

  static String? getRole() {
    final userData = getUserData();
    return userData?['role'];
  }

  static Future<void> clearAll() async {
    await _storage.erase();
  }
}
