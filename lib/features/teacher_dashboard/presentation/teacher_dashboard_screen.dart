// lib/features/teacher_dashboard/presentation/teacher_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:educheck/features/core/common_widgets/course_card.dart'; 
import 'package:educheck/features/teacher_dashboard/presentation/add_class_dialog.dart';
import 'package:educheck/features/profile/presentation/settings_dialog.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // All Classes, Categories, Archived
      child: Scaffold(
        body: Column(
          children: [
            _buildAppBar(context),
            const _buildTabBar(),
            const Expanded(
              child: TabBarView(
                children: [
                  AllClassesTab(),
                  CategoriesTab(),
                  ArchivedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 8),
      decoration: BoxDecoration(color: Colors.grey.shade50),
      child: Row(
        children: [
          // User Profile Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF6F35A5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'T',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Info
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dr. Smith',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Professor',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          // Add Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6F35A5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const Dialog(
                      insetPadding: EdgeInsets.all(20), 
                      child: AddClassDialog(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _buildTabBar extends StatelessWidget {
  const _buildTabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: TabBar(
        labelColor: const Color(0xFF6F35A5),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF6F35A5),
        indicatorWeight: 3.0,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: [
          const Tab(text: 'All Classes'),
          const Tab(text: 'Categories'),
          const Tab(text: 'Archived'),
          // Using a placeholder for settings icon, though typically it's an IconButton in the header.
          Tab(icon: IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () {
               showModalBottomSheet(
                context: context,
                builder: (_) => const SettingsDialog(),
               );
            },
          )),
        ],
      ),
    );
  }
}

// --- TAB VIEWS ---

class AllClassesTab extends StatelessWidget {
  const AllClassesTab({super.key});
  
  // Mock data for the dashboard display
  final List<Map<String, dynamic>> classes = const [
    {'title': 'Mathematics', 'subtitle': 'Grade 10', 'detail': '25 students', 'status': '2 pending', 'colors': [Color(0xFFFF9A9E), Color(0xFFFAD0C4)], 'showOptions': true},
    {'title': 'Physics', 'subtitle': 'Grade 12', 'detail': '18 students', 'status': 'All clear', 'colors': [Color(0xFF8EC5FC), Color(0xFFE0C3FC)], 'showOptions': true},
    {'title': 'Chemistry', 'subtitle': 'Grade 11', 'detail': '22 students', 'status': 'All clear', 'colors': [Color(0xFFFFECD2), Color(0xFFFCB69F)], 'showOptions': true},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: classes.map((data) => CourseCard(
        title: data['title'],
        subtitle: data['subtitle'],
        detail: data['detail'],
        statusText: data['status'],
        gradientColors: data['colors'],
        showMoreOptions: data['showOptions'],
        onTap: () { /* Navigate to Classroom Details */ },
      )).toList(),
    );
  }
}

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildCategoryGroup(context, 'Grade 10', 'Mathematics', '25 students', [const Color(0xFFFF9A9E), const Color(0xFFFAD0C4)]),
        _buildCategoryGroup(context, 'Grade 11', 'Chemistry', '22 students', [const Color(0xFFFFECD2), const Color(0xFFFCB69F)]),
        _buildCategoryGroup(context, 'Grade 12', 'Physics', '18 students', [const Color(0xFF8EC5FC), const Color(0xFFE0C3FC)]),
      ],
    );
  }

  Widget _buildCategoryGroup(BuildContext context, String groupTitle, String className, String studentCount, List<Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(groupTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        CourseCard(
          title: className,
          subtitle: studentCount,
          detail: '', // No detail in this view
          statusText: '',
          gradientColors: colors,
          onTap: () { /* Navigate to Class Detail */ },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}


class ArchivedTab extends StatelessWidget {
  const ArchivedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.keyboard_arrow_down, size: 60, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'No archived classes yet',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
