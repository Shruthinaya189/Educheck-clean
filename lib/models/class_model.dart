import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String name;
  final String code;
  final String category;
  final String teacherId;
  final List<String> enrolledStudents;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassModel({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.teacherId,
    required this.enrolledStudents,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // From Firestore
  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      category: data['category'] ?? '',
      teacherId: data['teacherId'] ?? '',
      enrolledStudents: List<String>.from(data['enrolledStudents'] ?? []),
      isArchived: data['isArchived'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // From API JSON (for backward compatibility)
  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      category: json['category'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      enrolledStudents: List<String>.from(json['enrolled_students'] ?? []),
      isArchived: json['is_archived'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'category': category,
      'teacherId': teacherId,
      'enrolledStudents': enrolledStudents,
      'isArchived': isArchived,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
