// lib/features/classroom/domain/entities/test_entity.dart

import 'package:equatable/equatable.dart';

enum TestStatus { pending, completed }

class TestEntity extends Equatable {
  final String id;
  final String title;
  final String dueDate;
  final int totalMarks;
  final TestStatus status;
  final int? score; // Nullable for pending tests

  const TestEntity({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.totalMarks,
    required this.status,
    this.score,
  });

  @override
  List<Object?> get props => [id, title, dueDate, totalMarks, status, score];
}