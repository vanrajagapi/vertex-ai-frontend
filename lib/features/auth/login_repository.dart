import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_client.dart';
import '../../core/utils/logger.dart';

abstract class ILoginRepository {
  Future<bool> login(String email, String password);
}

class LoginRepository implements ILoginRepository {
  final Dio _dio = ApiClient.createDio();

  @override
  Future<bool> login(String username, String password) async {
    _dio.options.baseUrl = AppConfig.baseUrl;
    AppLogger.printData("username", username);
    AppLogger.printData("password", password);
    try {
      final response = await _dio.post(
        '/api/v1/auth/token',
        data: {'username': username, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      AppLogger.printData("login status", response.statusCode.toString());

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        if (token != null) {
          await StorageService.saveToken(token);
          await StorageService.saveUserData(response.data);
        }
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.printData("Login Error", e.toString());
      return false;
    }
  }
}
