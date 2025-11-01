// lib/features/classroom/presentation/classroom_screen.dart

import 'package:flutter/material.dart';
import 'package:educheck/features/classroom/presentation/test_list_tab.dart';

class ClassroomScreen extends StatelessWidget {
  final String courseName;
  final String instructor;

  const ClassroomScreen({
    super.key,
    required this.courseName,
    required this.instructor,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1, 
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.of(context).pop(),
          ),
          // FIX: Use Column for the title to display two lines of text
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(courseName, style: const TextStyle(fontSize: 18)),
              Text(
                instructor,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Available Tests'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TestListTab(),
          ],
        ),
      ),
    );
  }
}