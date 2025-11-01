import 'package:flutter/material.dart';
import 'package:educheck_app/features/classroom/domain/entities/student_entity.dart';

class StudentListTab extends StatelessWidget {
  final String classId;

  const StudentListTab({super.key, required this.classId});

  final List<StudentEntity> students = const [
    StudentEntity(id: 's1', rollNumber: 'S001', name: 'Smith, Alice', isActive: true),
    StudentEntity(id: 's2', rollNumber: 'S002', name: 'Johnson, Bob', isActive: true),
    StudentEntity(id: 's3', rollNumber: 'S003', name: 'Williams, Charlie', isActive: false),
    StudentEntity(id: 's4', rollNumber: 'S004', name: 'Brown, Diana', isActive: true),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          elevation: 1,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: student.isActive ? Colors.green.shade50 : Colors.red.shade50,
              child: Icon(
                student.isActive ? Icons.person_check : Icons.person_off, 
                color: student.isActive ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Roll No: ${student.rollNumber}'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'absent') { /* Mark Absent Logic */ }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'absent', child: Text('Mark as Absent', style: TextStyle(color: Colors.red))),
              ],
              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
            ),
            onTap: () {
              // Navigate to student detail view for this class
            },
          ),
        );
      },
    );
  }
}