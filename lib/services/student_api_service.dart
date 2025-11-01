import 'api_service.dart';
import '../models/class_model.dart';

class StudentApiService {
  final ApiService _apiService = ApiService();

  Future<ClassModel> joinClass(String code) async {
    final data = await _apiService.post('/api/student/join', body: {'code': code});
    return ClassModel.fromJson(data);
  }

  Future<List<ClassModel>> getMyClasses() async {
    final data = await _apiService.get('/api/student/classes');
    return (data as List).map((json) => ClassModel.fromJson(json)).toList();
  }
}
