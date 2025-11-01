import 'package:flutter/material.dart';
import 'package:educheck_app/core/colors.dart';

class CreateTestDialog extends StatelessWidget {
  const CreateTestDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Test'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Test Name (e.g., Midterm Exam)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Total Marks',
                border: OutlineInputBorder(),
              ),
              value: 50,
              items: const [
                DropdownMenuItem(value: 20, child: Text('20 Marks')),
                DropdownMenuItem(value: 50, child: Text('50 Marks')),
                DropdownMenuItem(value: 100, child: Text('100 Marks')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () { /* Placeholder for Date Picker */ },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Set Due Date'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              "Question paper and answer key can be uploaded after creation in the test details screen.", 
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { /* Create Test Logic */ Navigator.of(context).pop(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentOrange),
          child: const Text('Create', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}