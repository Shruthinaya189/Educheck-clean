import 'package:flutter/material.dart';
import '../../models/class_model.dart';

class StudentClassDetailScreen extends StatelessWidget {
  final ClassModel classModel;

  const StudentClassDetailScreen({super.key, required this.classModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(classModel.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${classModel.code}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Category: ${classModel.category}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Tests will appear here soon.', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
