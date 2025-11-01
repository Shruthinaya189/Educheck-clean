import 'dart:convert';
import 'package:http/http.dart' as http; // Import http
import '../config/api_config.dart';
import 'api_service.dart';
import 'token_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();

  Future<void> login(String email, String password) async {
    try {
      // Send as OAuth2 form with explicit grant_type and scope
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.authLogin),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email,
          'password': password,
          'grant_type': 'password',
          'scope': '',
          // 'client_id': '',       // only if your backend expects it
          // 'client_secret': '',   // only if your backend expects it
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _tokenService.saveToken(data['access_token']);
        return;
      }

      // Try to surface backend error details
      try {
        final data = jsonDecode(response.body);
        final detail = data['detail']?.toString() ??
            data['error_description']?.toString() ??
            'Login failed (${response.statusCode}).';
        throw ApiException(detail);
      } catch (_) {
        // Not JSON, return raw body or status
        throw ApiException(
          response.body.isNotEmpty
              ? response.body
              : 'Login failed (${response.statusCode}).',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Could not reach server. Check network and try again.');
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // The register endpoint expects JSON.
      await _apiService.post(
        ApiConfig.authRegister,
        body: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _tokenService.deleteToken();
  }

  Future<bool> isLoggedIn() async {
    return await _tokenService.hasToken();
  }

  // Returns 'teacher' | 'student' or null if not valid
  Future<String?> currentUserRole() async {
    try {
      final me = await _apiService.get(ApiConfig.authMe);
      final role = (me is Map && me['role'] is String) ? me['role'] as String : null;
      return role;
    } catch (_) {
      return null;
    }
  }

  Future<void> googleLogin(String idToken) async {
    try {
      final resp = await http.post(
        Uri.parse(ApiConfig.baseUrl + ApiConfig.authGoogle),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        await _tokenService.saveToken(data['access_token']);
        return;
      }
      // try to parse error
      try {
        final data = jsonDecode(resp.body);
        throw ApiException(data['detail']?.toString() ?? 'Google login failed (${resp.statusCode})');
      } catch (_) {
        throw ApiException('Google login failed (${resp.statusCode})');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Could not reach server for Google login.');
    }
  }
}
