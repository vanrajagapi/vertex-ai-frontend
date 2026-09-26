import '../services/storage_service.dart';

class AppConfig {
  // Replace this placeholder with your actual Gemini API Key
  static const String geminiApiKey = 'AIzaSyAvx8pTT21LKoBCEHIuHS4mwY8XIdecQBo';
  static const String defaultBaseUrl =
      'https://scrubbed-excess-ability.ngrok-free.dev';

  static String get baseUrl => StorageService.getBaseUrl() ?? defaultBaseUrl;
}
