import 'dart:convert';

class ClassModel {
  final String id;
  final String name;
  final String code;
  final String category;
  final String teacherId;
  final List<String> enrolledStudents;
  final bool isArchived;

  ClassModel({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.teacherId,
    this.enrolledStudents = const [],
    this.isArchived = false,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      category: json['category'],
      teacherId: json['teacher_id'],
      enrolledStudents: List<String>.from(json['enrolled_students'] ?? []),
      isArchived: json['is_archived'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'category': category,
      'teacherId': teacherId,
      'enrolledStudents': enrolledStudents,
      'isArchived': isArchived,
    };
  }

  ClassModel copyWith({
    String? id,
    String? name,
    String? code,
    String? category,
    String? teacherId,
    List<String>? enrolledStudents,
    bool? isArchived,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      teacherId: teacherId ?? this.teacherId,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}