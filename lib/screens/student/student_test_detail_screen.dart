import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/test_model.dart';
import '../../services/test_api_service.dart';
import '../../config/api_config.dart';
import 'package:http/http.dart' as http;

class StudentTestDetailScreen extends StatefulWidget {
  final TestModel testModel;
  const StudentTestDetailScreen({super.key, required this.testModel});

  @override
  State<StudentTestDetailScreen> createState() => _StudentTestDetailScreenState();
}

class _StudentTestDetailScreenState extends State<StudentTestDetailScreen> {
  final TestApiService _testApiService = TestApiService();
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;
  StudentSubmission? _mySubmission;
  bool _loading = false;
  String? _error;
  final String _studentId = 'student@demo.com'; // Mock student ID

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 300)); // Mock delay
    setState(() {
      // Mock submission data
      _mySubmission ??= StudentSubmission(
        id: 'sub_${widget.testModel.id}',
        studentId: _studentId,
        studentName: 'Demo Student',
        testId: widget.testModel.id, // Added missing parameter
      );
      _loading = false;
    });
  }

  Future<void> _onScan() async {
    final List<String>? images = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnswerSheetScanner(
          studentName: _mySubmission!.studentName, // Added missing parameter
          testName: widget.testModel.name, // Added missing parameter
        ),
      ),
    );
    if (images != null && images.isNotEmpty) {
      final pdfFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => ScannedPagesPreview(
            scannedPages: images, // Corrected parameter name
            studentName: _mySubmission!.studentName, // Added missing parameter
            testName: widget.testModel.name, // Added missing parameter
          ),
        ),
      );
      if (pdfFile != null) {
        setState(() {
          _mySubmission = _mySubmission?.copyWith(answerSheetUrl: pdfFile.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved answer sheet to ${pdfFile.path}')),
        );
      }
    }
  }

  Future<void> _raiseQuery() async {
    final queryController = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raise Query'),
        content: TextField(controller: queryController, decoration: const InputDecoration(labelText: 'Your Query')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, queryController.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (query != null && query.isNotEmpty) {
      setState(() {
        _mySubmission = _mySubmission?.copyWith(query: query);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Query submitted')));
    }
  }

  Future<void> _uploadAnswerSheet() async {
    final images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;

    setState(() => _uploading = true);

    try {
      // Upload images to /api/uploads/images-to-pdf (reuse existing endpoint)
      final uri = Uri.parse(ApiConfig.baseUrl + '/api/uploads/images-to-pdf');
      final req = http.MultipartRequest('POST', uri);
      for (final img in images) {
        req.files.add(await http.MultipartFile.fromPath('files', img.path, filename: img.name));
      }
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode != 200) throw Exception('Upload failed');

      // Extract URL from response
      final data = (await http.Response.fromStream(await req.send())).body;
      // Assuming response is {"url": "/uploads/....pdf"}
      // For simplicity, we'll just send the images list as URLs (or you can store PDF URL)
      // Here we'll assume images are stored and we have their URLs
      // For now, let's just submit a dummy list
      final imageUrls = images.map((e) => '/uploads/${e.name}').toList();

      await _testApiService.submitAnswerSheet(widget.testModel.id, imageUrls);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Answer sheet submitted!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.testModel.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _mySubmission == null
                  ? const Center(child: Text('No submission found.'))
                  : _buildSubmissionDetails(),
    );
  }

  Widget _buildSubmissionDetails() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Upload Section
        if (widget.testModel.allowStudentUpload && _mySubmission?.answerSheetUrl == null)
          ElevatedButton.icon(onPressed: _onScan, icon: const Icon(Icons.camera_alt), label: const Text('Scan & Upload Answer Sheet')),
        
        // View Uploaded Section
        if (_mySubmission?.answerSheetUrl != null)
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('View My Answer Sheet'),
            subtitle: Text(_mySubmission!.answerSheetUrl!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () { /* TODO: Open PDF */ },
          ),

        const Divider(height: 32),

        // Marks Section
        if (_mySubmission?.isPublished == true)
          Card(
            child: ListTile(
              title: const Text('Marks Obtained'),
              trailing: Text(
                '${_mySubmission?.marksObtained ?? 0} / ${widget.testModel.totalMarks}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),

        // Query Section
        if (_mySubmission?.isPublished == true) ...[
          const SizedBox(height: 16),
          if (_mySubmission?.query == null)
            ElevatedButton.icon(onPressed: _raiseQuery, icon: const Icon(Icons.question_answer), label: const Text('Raise a Query')),
          if (_mySubmission?.query != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Query', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_mySubmission!.query!),
                    if (_mySubmission!.queryResponse != null) ...[
                      const Divider(height: 24),
                      const Text('Teacher\'s Response', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 8),
                      Text(_mySubmission!.queryResponse!),
                    ]
                  },
                ),
              ),
            ),
        ],
      ],
    );
  }
}
