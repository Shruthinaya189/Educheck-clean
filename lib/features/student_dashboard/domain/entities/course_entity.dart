// lib/features/student_dashboard/domain/entities/course_entity.dart 

import 'package:equatable/equatable.dart';

class CourseEntity extends Equatable {
  final String id;
  final String name;
  final String code;
  final String instructor;
  final int testsAvailable;
  final int testsPending;

  const CourseEntity({
    required this.id,
    required this.name,
    required this.code,
    required this.instructor,
    required this.testsAvailable,
    required this.testsPending,
  });

  @override
  List<Object> get props => [
        id,
        name,
        code,
        instructor,
        testsAvailable,
        testsPending,
      ];
}
