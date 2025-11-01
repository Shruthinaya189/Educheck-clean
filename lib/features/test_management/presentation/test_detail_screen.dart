import 'package:flutter/material.dart';
import 'package:educheck_app/features/classroom/domain/entities/test_entity.dart';
import 'package:educheck_app/core/colors.dart';

class TestDetailScreen extends StatefulWidget {
  final TestEntity testDetails;
  
  const TestDetailScreen({super.key, required this.testDetails});

  @override
  State<TestDetailScreen> createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends State<TestDetailScreen> {
  bool isAiCorrectionEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testDetails.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _showUploadOptions(context),
            tooltip: 'Upload Files',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestSummary(),
            _buildAISettings(),
            _buildActionButtons(),
            const Divider(height: 30),
            _buildStudentSubmissionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSummary() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Marks: ${widget.testDetails.totalMarks}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Status: ${widget.testDetails.status.name.split('.').last}', style: TextStyle(color: widget.testDetails.statusColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAISettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SwitchListTile(
        title: const Text('Enable AI Correction', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('AI will attempt to correct papers. Teacher can manually override.'),
        value: isAiCorrectionEnabled,
        onChanged: (bool value) => setState(() => isAiCorrectionEnabled = value),
        activeColor: AppColors.primaryBlue,
        secondary: const Icon(Icons.auto_fix_high),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Wrap(
        spacing: 10,
        children: [
          ElevatedButton.icon(
            onPressed: () { /* Start AI correction process */ },
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text('AI Correct Papers'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white),
          ),
          ElevatedButton.icon(
            onPressed: () { /* Publish marks logic */ },
            icon: const Icon(Icons.publish),
            label: const Text('Publish Results'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStudentSubmissionList() {
    final List<Map<String, dynamic>> submissions = [
      {'name': 'Alice Smith', 'roll': 'S001', 'submitted': true, 'corrected': true, 'marks': 45},
      {'name': 'Bob Johnson', 'roll': 'S002', 'submitted': true, 'corrected': false, 'marks': null},
      {'name': 'Charlie Williams', 'roll': 'S003', 'submitted': false, 'corrected': false, 'marks': null},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
          child: Text('Student Submissions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final sub = submissions[index];
            return ListTile(
              leading: Icon(sub['submitted'] ? Icons.check_circle : Icons.cancel, 
                            color: sub['submitted'] ? Colors.green : Colors.red),
              title: Text(sub['name']),
              subtitle: Text('Roll: ${sub['roll']}'),
              trailing: sub['submitted'] 
                ? _buildSubmissionActions(context, sub)
                : const Text('Absent', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: sub['submitted'] ? () { /* View corrected paper */ } : null,
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildSubmissionActions(BuildContext context, Map<String, dynamic> sub) {
    if (sub['corrected']) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Marks: ${sub['marks']}/${widget.testDetails.totalMarks}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          const Icon(Icons.visibility, color: AppColors.primaryBlue),
        ],
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () => _showScanOptions(context),
        icon: const Icon(Icons.scanner_outlined, size: 18),
        label: const Text('Scan/Upload'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentOrange, foregroundColor: Colors.white, elevation: 0),
      );
    }
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.assignment_outlined), title: const Text('Upload Question Paper (PDF)'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.vpn_key_outlined), title: const Text('Upload Answer Key (PDF/Text)'), onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }
  
  void _showScanOptions(BuildContext context) {
     showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Scan Multiple Pages (Camera)'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.folder_open), title: const Text('Upload from Files (PDF/Images)'), onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}