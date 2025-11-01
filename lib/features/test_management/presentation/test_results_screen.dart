import 'package:flutter/material.dart';
import 'package:educheck_app/features/classroom/domain/entities/test_entity.dart';
import 'package:educheck_app/core/colors.dart';

class TestResultsScreen extends StatelessWidget {
  final TestEntity testDetails;

  const TestResultsScreen({super.key, required this.testDetails});

  final List<Map<String, dynamic>> results = const [
    {'name': 'Alice Smith', 'roll': 'S001', 'marks': 45},
    {'name': 'Bob Johnson', 'roll': 'S002', 'marks': 38},
    {'name': 'Diana Brown', 'roll': 'S004', 'marks': 49},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${testDetails.name} Results'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          _buildSummaryHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(result['roll'].toString().substring(1), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(result['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Roll No: ${result['roll']}'),
                  trailing: Text(
                    '${result['marks']} / ${testDetails.totalMarks}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: result['marks'] > (testDetails.totalMarks * 0.7) ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                  onTap: () {
                    // Navigate to view corrected paper / query history
                  },
                );
              },
            ),
          ),
          _buildQuerySection(context),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.green.shade50,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Papers Corrected: ${results.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text('Total Marks Possible: ${testDetails.totalMarks}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildQuerySection(BuildContext context) {
    // Placeholder for query data
    final List<Map<String, String>> queries = [
      {'student': 'Alice Smith', 'query': 'Q3 marking error', 'status': 'New'},
    ];

    return Card(
      margin: const EdgeInsets.all(16),
      child: ExpansionTile(
        title: Text('Student Queries (${queries.length})', style: TextStyle(color: queries.isNotEmpty ? AppColors.accentOrange : Colors.grey)),
        children: queries.map((q) {
          return ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.accentOrange),
            title: Text(q['student']!),
            subtitle: Text(q['query']!),
            trailing: Text(q['status']!, style: const TextStyle(color: Colors.red)),
            onTap: () { /* Open Query Resolution Screen */ },
          );
        }).toList(),
      ),
    );
  }
}