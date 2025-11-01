import 'api_service.dart';
import '../models/test_model.dart';

class TestApiService {
  final ApiService _apiService = ApiService();

  Future<TestModel> createTest(int classId, Map<String, dynamic> testData) async {
    final data = await _apiService.post('/api/teacher/classes/$classId/tests', body: testData);
    return TestModel.fromJson(data);
  }

  Future<List<TestModel>> getClassTests(int classId) async {
    final data = await _apiService.get('/api/teacher/classes/$classId/tests');
    return (data as List).map((json) => TestModel.fromJson(json)).toList();
  }

  Future<List<TestModel>> getClassTestsStudent(int classId) async {
    final data = await _apiService.get('/api/student/classes/$classId/tests');
    return (data as List).map((json) => TestModel.fromJson(json)).toList();
  }

  Future<void> submitAnswerSheet(int testId, List<String> imageUrls) async {
    await _apiService.post('/api/student/submissions', body: {
      'test_id': testId,
      'image_urls': imageUrls,
    });
  }
}
