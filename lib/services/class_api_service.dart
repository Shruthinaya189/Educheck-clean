import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../models/api_exception.dart';
import '../models/class_model.dart';

class ClassApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Create class in Firestore (real-time sync)
  Future<void> createClass(Map<String, dynamic> classData) async {
    final userId = _userId;
    if (userId == null) throw ApiException('User not authenticated');

    await _firestore.collection('classes').add({
      ...classData,
      'teacherId': userId,
      'enrolledStudents': [],
      'isArchived': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get teacher classes (real-time stream)
  Future<List<ClassModel>> getTeacherClasses({bool forceRefresh = false}) async {
    final userId = _userId;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList();
  }

  // Update class
  Future<void> updateClass(String classId, Map<String, dynamic> updates) async {
    await _firestore.collection('classes').doc(classId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete class
  Future<void> deleteClass(String classId) async {
    final userId = _userId;
    if (userId == null) throw ApiException('User not authenticated');

    final doc = await _firestore.collection('classes').doc(classId).get();
    if (doc.data()?['teacherId'] != userId) {
      throw ApiException('Unauthorized');
    }

    await _firestore.collection('classes').doc(classId).delete();
  }
}
