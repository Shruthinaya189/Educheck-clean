// lib/features/student_dashboard/presentation/student_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:educheck/features/student_dashboard/domain/entities/course_entity.dart';
import 'package:educheck/features/core/common_widgets/course_card.dart'; 
import 'package:educheck/features/profile/presentation/settings_dialog.dart'; 
import 'package:educheck/features/classroom/presentation/classroom_screen.dart'; // Detail View

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  final List<CourseEntity> courses = const [
    CourseEntity(
      id: 'C101',
      name: 'Mathematics 101',
      code: 'MATH101',
      instructor: 'Dr. Smith',
      testsAvailable: 3,
      testsPending: 1,
    ),
    CourseEntity(
      id: 'C102',
      name: 'Physics 101',
      code: 'PHY101',
      instructor: 'Dr. Wilson',
      testsAvailable: 2,
      testsPending: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'My Courses',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...courses.map((course) => CourseCard(
            title: course.name,
            subtitle: '${course.instructor} • ${course.code}',
            detail: '${course.testsAvailable} tests available',
            statusText: course.testsPending > 0 ? '${course.testsPending} pending' : 'All clear',
            gradientColors: course.testsPending > 0 
                ? [const Color(0xFFFF9A9E), const Color(0xFFFAD0C4)]
                : [const Color(0xFF96E6B3), const Color(0xFF76BA99)],
            onTap: () {
               Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ClassroomScreen(courseName: course.name, instructor: course.instructor)),
               );
            },
          )).toList(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80.0),
      child: Padding(
        padding: const EdgeInsets.only(top: 40.0, left: 16, right: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('S',
                    style: TextStyle(color: Colors.white, fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sarah Johnson',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Roll: 2023001',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.black54),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => const SettingsDialog(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}