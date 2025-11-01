import 'api_service.dart';
import '../config/api_config.dart';
import '../models/class_model.dart';

class ClassApiService {
  final ApiService _apiService = ApiService();
  
  // Simple cache
  List<ClassModel>? _cachedClasses;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(seconds: 30);

  Future<List<ClassModel>> getTeacherClasses({bool forceRefresh = false}) async {
    // Return cache if valid and not forcing refresh
    if (!forceRefresh && _cachedClasses != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedClasses!;
      }
    }

    final data = await _apiService.get('/api/teacher/classes');
    final classes = (data as List).map((json) => ClassModel.fromJson(json)).toList();
    
    // Update cache
    _cachedClasses = classes;
    _cacheTime = DateTime.now();
    
    return classes;
  }

  // Clear cache when creating/updating/deleting
  Future<ClassModel> createClass(Map<String, dynamic> classData) async {
    final data = await _apiService.post('/api/teacher/classes', body: classData);
    _cachedClasses = null;
    return ClassModel.fromJson(data);
  }

  Future<void> updateClass(int classId, Map<String, dynamic> updates) async {
    await _apiService.put('/api/teacher/classes/$classId', body: updates);
    _cachedClasses = null;
  }

  Future<void> deleteClass(int classId) async {
    await _apiService.delete('/api/teacher/classes/$classId');
    _cachedClasses = null; // invalidate cache
  }
}
