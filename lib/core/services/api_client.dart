import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import '../config/app_config.dart';
import 'storage_service.dart';
import '../../features/auth/login_screen.dart';

class ApiClient {
  static Dio createDio({Duration? connectTimeout, Duration? receiveTimeout}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: connectTimeout ?? const Duration(seconds: 10),
        receiveTimeout: receiveTimeout ?? const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException err, handler) {
          if (err.response?.statusCode == 401) {
            final isLoginRequest = err.requestOptions.path.contains('/auth/token');

            if (!isLoginRequest) {
              // Clear stored credentials and token
              StorageService.clearAll();
              
              // Notify user
              Get.rawSnackbar(
                title: 'Unauthorized',
                message: 'Your session has expired or you are unauthorized. Please log in again.',
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 3),
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(16),
                borderRadius: 8,
              );
              
              // Navigate to Login Screen and clear route history
              Get.offAll(() => const LoginScreen());
            }
          }
          return handler.next(err);
        },
      ),
    );

    return dio;
  }
}
