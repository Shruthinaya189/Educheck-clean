class ApiConfig {
  // Your PC's IP (from ipconfig)
  static const String baseUrl = 'http://10.1.224.67:8000';

  // FastAPI endpoints
  static const String authLogin = '/api/auth/login';
  static const String authRegister = '/api/auth/register';
  static const String authMe = '/api/auth/me';
  static const String authGoogle = '/api/auth/google';

  // For Android, get this from: android/app/google-services.json → oauth_client → client_id (type 3)
  static const String googleAndroidClientId = 'YOUR_ANDROID_CLIENT_ID'; // Android OAuth client
  
  // Cache timeout for API calls (5 minutes)
  static const Duration cacheTimeout = Duration(minutes: 5);
}
