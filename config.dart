/// App-wide configuration constants
class AppConfig {
  static const String appName = 'MindMirror';
  static const String appVersion = '1.0.0';
  static const bool isDebugMode = bool.fromEnvironment('DEBUG_MODE', defaultValue: false);

  // ✅ Legacy support for older code
  static const String baseUrl = ApiConfig.baseUrl;
}

/// Backend API configuration
class ApiConfig {
  // Base URL for all API requests
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.mindmirror.it.com',
  );

  // API endpoints
  static const String chat = '/chat';
  static const String uploadImage = '/upload_chat_image';
  static const String chatHistory = '/chat/history/today';
  static const String health = '/health';
  static const String insightSummary = '/insight/summary';
  static const String insightCoaching = '/insight/coaching';
  static const String insightHighlight = '/insight/highlight';
  static const String diaryByDate = '/diary/by-date';
  static const String diarySubmit = '/diary/submit';
  static const String survey = '/survey';
  static const String historyByDate = '/history/by-date';
}

/// Firebase configuration (build-time injected)
class FirebaseConfig {
  static const String projectId = 'mindmirror-65e9f';
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String measurementId = String.fromEnvironment('FIREBASE_APP_MEASUREMENT_ID');
}
