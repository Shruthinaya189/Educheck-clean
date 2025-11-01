// lib/features/teacher_dashboard/domain/entities/class_entity.dart

import 'package:equatable/equatable.dart';

class ClassEntity extends Equatable {
  final String id;
  final String name;
  final String grade;
  final int studentCount;
  final int pendingAssignments;

  const ClassEntity({
    required this.id,
    required this.name,
    required this.grade,
    required this.studentCount,
    required this.pendingAssignments,
  });

  @override
  List<Object> get props => [id, name, grade, studentCount, pendingAssignments];
}
