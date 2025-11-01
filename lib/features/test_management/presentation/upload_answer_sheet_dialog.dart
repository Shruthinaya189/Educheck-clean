// lib/features/test_management/presentation/upload_answer_sheet_dialog.dart

import 'package:flutter/material.dart';

class UploadAnswerSheetDialog extends StatelessWidget {
  const UploadAnswerSheetDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload Answer Sheet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Scan Pages Button (Purple)
            ElevatedButton.icon(
              onPressed: () { /* Scan Pages Logic */ },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Pages'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A0DAD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const SizedBox(height: 16),
            
            // Upload Files Button (Blue)
            ElevatedButton.icon(
              onPressed: () { /* Upload Files Logic */ },
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload Files'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const SizedBox(height: 24),
            
            // Cancel Button (Gray)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
            ),
          ],
        ),
      ),
    );
  }
}