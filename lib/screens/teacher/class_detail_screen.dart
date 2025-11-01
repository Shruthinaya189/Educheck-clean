import 'package:flutter/material.dart';
import '../../models/class_model.dart';

class ClassDetailScreen extends StatelessWidget {
  final ClassModel classModel;

  const ClassDetailScreen({super.key, required this.classModel});

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
            const Text('Students:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: classModel.enrolledStudents.isEmpty
                  ? const Center(child: Text('No students yet.'))
                  : ListView.builder(
                      itemCount: classModel.enrolledStudents.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(classModel.enrolledStudents[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
