// lib/features/classroom/presentation/test_list_tab.dart

import 'package:flutter/material.dart';
import 'package:educheck/features/classroom/domain/entities/test_entity.dart';
import 'package:educheck/features/test_management/presentation/raise_query_dialog.dart';
import 'package:educheck/features/test_management/presentation/upload_answer_sheet_dialog.dart';

class TestListTab extends StatelessWidget {
  const TestListTab({super.key});

  final List<TestEntity> tests = const [
    TestEntity(
      id: 'T201',
      title: 'Midterm Exam',
      dueDate: 'Due: Tomorrow',
      totalMarks: 50,
      status: TestStatus.pending,
    ),
    TestEntity(
      id: 'T202',
      title: 'Quiz 1',
      dueDate: 'Completed',
      totalMarks: 20,
      score: 18,
      status: TestStatus.completed,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Available Tests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...tests.map((test) => TestItemCard(test: test)).toList(),
      ],
    );
  }
}

class TestItemCard extends StatelessWidget {
  final TestEntity test;
  const TestItemCard({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    final bool isPending = test.status == TestStatus.pending;
    final Color primaryActionColor = isPending ? const Color(0xFF6A0DAD) : Colors.blue;
    final String primaryActionText = isPending ? 'Upload Answer' : 'View Result';
    final String statusLabel = isPending ? 'Pending' : '${test.score}/${test.totalMarks}';
    final Color statusBgColor = isPending ? Colors.red.shade100 : Colors.green.shade100;
    final Color statusTextColor = isPending ? Colors.red.shade700 : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                test.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusTextColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isPending ? test.dueDate : test.dueDate,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Text('${test.totalMarks} marks', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Primary Action Button (Upload/View)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isPending) {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => const UploadAnswerSheetDialog(),
                      );
                    } else {
                      // TODO: Navigate to View Result Screen
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryActionColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(primaryActionText, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              // Query Button
              _buildQueryButton(context),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildQueryButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => const RaiseQueryDialog(),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: const Text('Query', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}