import 'api_service.dart';

class ProfileApiService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getMyProfile() async {
    return await _apiService.get('/api/profile/me');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates) async {
    return await _apiService.put('/api/profile/me', updates);
  }
}
