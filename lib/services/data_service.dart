import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/class_model.dart';
import '../models/test_model.dart';
import '../models/student_submission.dart';

class DataService {
  static const _uuid = Uuid();
  
  // Classes
  Future<List<ClassModel>> getTeacherClasses(String teacherId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('classes_$teacherId');
    if (json == null) return [];
    
    final List<dynamic> data = jsonDecode(json);
    return data.map((e) => ClassModel.fromJson(e)).toList();
  }

  Future<void> saveClass(ClassModel classModel) async {
    final prefs = await SharedPreferences.getInstance();
    final classes = await getTeacherClasses(classModel.teacherId);
    classes.add(classModel);
    
    final json = jsonEncode(classes.map((e) => e.toJson()).toList());
    await prefs.setString('classes_${classModel.teacherId}', json);
  }

  Future<void> updateClass(ClassModel classModel) async {
    final prefs = await SharedPreferences.getInstance();
    final classes = await getTeacherClasses(classModel.teacherId);
    final index = classes.indexWhere((c) => c.id == classModel.id);
    if (index != -1) {
      classes[index] = classModel;
      final json = jsonEncode(classes.map((e) => e.toJson()).toList());
      await prefs.setString('classes_${classModel.teacherId}', json);
    }
  }

  Future<void> deleteClass(String classId, String teacherId) async {
    final prefs = await SharedPreferences.getInstance();
    final classes = await getTeacherClasses(teacherId);
    classes.removeWhere((c) => c.id == classId);
    
    final json = jsonEncode(classes.map((e) => e.toJson()).toList());
    await prefs.setString('classes_$teacherId', json);
  }

  String generateClassCode() {
    return 'CLASS${DateTime.now().millisecondsSinceEpoch % 100000}';
  }

  // Tests
  Future<List<TestModel>> getClassTests(String classId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('tests_$classId');
    if (json == null) return [];
    
    final List<dynamic> data = jsonDecode(json);
    return data.map((e) => TestModel.fromJson(e)).toList();
  }

  Future<void> saveTest(TestModel test) async {
    final prefs = await SharedPreferences.getInstance();
    final tests = await getClassTests(test.classId);
    tests.add(test);
    
    final json = jsonEncode(tests.map((e) => e.toJson()).toList());
    await prefs.setString('tests_${test.classId}', json);
  }

  // Student Submissions
  Future<List<StudentSubmission>> getTestSubmissions(String testId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('submissions_$testId');
    if (json == null) return [];
    
    final List<dynamic> data = jsonDecode(json);
    return data.map((e) => StudentSubmission.fromJson(e)).toList();
  }

  Future<void> saveSubmission(StudentSubmission submission) async {
    final prefs = await SharedPreferences.getInstance();
    final submissions = await getTestSubmissions(submission.testId);
    
    final index = submissions.indexWhere((s) => s.id == submission.id);
    if (index != -1) {
      submissions[index] = submission;
    } else {
      submissions.add(submission);
    }
    
    final json = jsonEncode(submissions.map((e) => e.toJson()).toList());
    await prefs.setString('submissions_${submission.testId}', json);
  }

  Future<ClassModel?> getClassByCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('classes_'));
    
    for (final key in keys) {
      final json = prefs.getString(key);
      if (json != null) {
        final List<dynamic> data = jsonDecode(json);
        final classes = data.map((e) => ClassModel.fromJson(e)).toList();
        final found = classes.where((c) => c.code == code && !c.isArchived).firstOrNull;
        if (found != null) return found;
      }
    }
    return null;
  }

  Future<void> enrollStudent(String classId, String studentId, String teacherId) async {
    final classes = await getTeacherClasses(teacherId);
    final classModel = classes.firstWhere((c) => c.id == classId);
    
    if (!classModel.enrolledStudents.contains(studentId)) {
      final updated = ClassModel(
        id: classModel.id,
        name: classModel.name,
        code: classModel.code,
        category: classModel.category,
        teacherId: classModel.teacherId,
        enrolledStudents: [...classModel.enrolledStudents, studentId],
        isArchived: classModel.isArchived,
      );
      await updateClass(updated);
    }
  }
}
