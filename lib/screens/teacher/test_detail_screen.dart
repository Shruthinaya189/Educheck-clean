import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/class_model.dart';
import '../../models/test_model.dart';
import '../../models/student_submission.dart';
import '../../services/data_service.dart';
import '../../services/test_api_service.dart';
import 'answer_sheet_scanner.dart';

class TestDetailScreen extends StatefulWidget {
  final TestModel test;
  final ClassModel classModel;

  const TestDetailScreen({
    super.key,
    required this.test,
    required this.classModel,
  });

  @override
  State<TestDetailScreen> createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends State<TestDetailScreen> {
  final DataService _dataService = DataService();
  final TestApiService _testApi = TestApiService();
  List<StudentSubmission> _submissions = [];
  bool _loadingSubs = false;
  String? _errorSubs;

  // Add these getters
  List<StudentSubmission> get pending => _submissions.where((s) => !s.isCorrected && !s.isAbsent).toList();
  List<StudentSubmission> get corrected => _submissions.where((s) => s.isCorrected && !s.isPublished).toList();
  List<StudentSubmission> get published => _submissions.where((s) => s.isPublished).toList();

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() {
      _loadingSubs = true;
      _errorSubs = null;
    });
    try {
      final subs = await _testApi.getSubmissions(widget.test.id);
      setState(() {
        _submissions = subs.map((e) => StudentSubmission.fromJson(e)).toList();
      });
    } catch (e) {
      setState(() => _errorSubs = 'Failed to load submissions');
    } finally {
      setState(() => _loadingSubs = false);
    }
  }

  Future<void> _updateMarks(StudentSubmission sub, int marks) async {
    await _testApi.updateMarks(sub.id, {"marks_obtained": marks, "is_corrected": true});
    _loadSubmissions();
  }

  Future<void> _publishMarks(StudentSubmission sub) async {
    await _testApi.publishMarks(sub.id);
    _loadSubmissions();
  }

  Future<void> _markAbsent(StudentSubmission sub) async {
    await _testApi.markAbsent(sub.id);
    _loadSubmissions();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.test.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Submissions'),
              Tab(text: 'Corrected'),
              Tab(text: 'Results'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              onPressed: _showAICorrectionDialog,
              tooltip: 'AI Correction',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _SubmissionsList(submissions: pending, onUpdateMarks: _updateMarks, onMarkAbsent: _markAbsent),
            _CorrectedList(submissions: corrected, test: widget.test, onUpdateMarks: _updateMarks, onPublish: _publishMarks),
            _ResultsList(submissions: published, test: widget.test),
          ],
        ),
      ),
    );
  }

  void _showAICorrectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Correction'),
        content: const Text(
          'AI correction will be integrated by your teammate.\n\nFor now, you can manually enter marks for each student.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanAnswerSheet(StudentSubmission submission) async {
    final pages = await Navigator.push<List<String>?>(
      context,
      MaterialPageRoute(
        builder: (_) => AnswerSheetScanner(
          studentName: submission.studentName,
          testName: widget.test.name,
        ),
      ),
    );
    if (pages == null || pages.isEmpty) return;

    final pdfPath = await _savePagesToPdf(pages);
    final updated = submission.copyWith(answerSheetUrl: pdfPath);
    await _dataService.saveSubmission(updated);
    await _loadSubmissions();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved answer sheet for ${submission.studentName}')));
  }

  Future<String> _savePagesToPdf(List<String> pages) async {
    // Delegated to preview screen already; keep here as fallback if needed.
    return pages.first; // placeholder if you already save in preview
  }

  Future<void> _uploadFile(StudentSubmission submission) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      final updated = submission.copyWith(
        answerSheetUrl: result.files.first.name,
      );
      await _dataService.saveSubmission(updated);
      await _loadSubmissions();
    }
  }

  Future<void> _manualCorrection(StudentSubmission submission) async {
    final marksController = TextEditingController();

    final marks = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Marks - ${submission.studentName}'),
        content: TextField(
          controller: marksController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Marks Obtained',
            hintText: 'Out of ${widget.test.totalMarks}',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(marksController.text);
              if (value != null && value <= widget.test.totalMarks) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (marks != null) {
      final updated = submission.copyWith(
        marksObtained: marks,
        isCorrected: true,
      );
      await _dataService.saveSubmission(updated);
      await _loadSubmissions();
    }
  }

  Future<void> _publishAllMarks() async {
    final corrected = _submissions.where((s) => s.isCorrected && !s.isPublished);

    for (final submission in corrected) {
      final updated = submission.copyWith(isPublished: true);
      await _dataService.saveSubmission(updated);
    }

    await _loadSubmissions();
    // _tabController.animateTo(2); // Uncomment if using TabController

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All marks published!')),
      );
    }
  }
}

class _SubmissionsList extends StatelessWidget {
  final List<StudentSubmission> submissions;
  final Function(StudentSubmission, int) onUpdateMarks;
  final Function(StudentSubmission) onMarkAbsent;

  const _SubmissionsList({
    required this.submissions,
    required this.onUpdateMarks,
    required this.onMarkAbsent,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_TestDetailScreenState>();
    final loading = state?._loadingSubs ?? false;
    final error = state?._errorSubs;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error));
    }

    final pendingSubmissions = submissions.where((s) => !s.isCorrected && !s.isAbsent).toList();

    if (pendingSubmissions.isEmpty) {
      return const Center(child: Text('All submissions corrected or marked absent'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingSubmissions.length,
      itemBuilder: (context, index) {
        final submission = pendingSubmissions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              child: Text(submission.studentName[0]),
            ),
            title: Text(submission.studentName),
            subtitle: Text(submission.answerSheetUrl == null ? 'Not uploaded' : 'Uploaded'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (submission.answerSheetUrl != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Answer sheet: ${submission.answerSheetUrl}',
                                style: TextStyle(color: Colors.green.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => state?._markAbsent(submission),
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text('Mark Absent'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => state?._scanAnswerSheet(submission),
                            icon: const Icon(Icons.document_scanner),
                            label: const Text('Scan'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => state?._uploadFile(submission),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload from Files'),
                    ),
                    if (submission.answerSheetUrl != null) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => state?._manualCorrection(submission),
                        icon: const Icon(Icons.edit),
                        label: const Text('Enter Marks Manually'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CorrectedList extends StatelessWidget {
  final List<StudentSubmission> submissions;
  final TestModel test; // Add this
  final Function(StudentSubmission, int) onUpdateMarks;
  final Function(StudentSubmission) onPublish;

  const _CorrectedList({
    required this.submissions,
    required this.test, // Add this
    required this.onUpdateMarks,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    if (submissions.isEmpty) {
      return const Center(child: Text('No submissions have been corrected yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(submission.studentName[0])),
            title: Text(submission.studentName),
            subtitle: Text('${submission.marksObtained ?? 0} / ${test.totalMarks}'),
            trailing: ElevatedButton(
              onPressed: () => onPublish(submission),
              child: const Text('Publish'),
            ),
          ),
        );
      },
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<StudentSubmission> submissions;
  final TestModel test; // Add this

  const _ResultsList({
    required this.submissions,
    required this.test, // Add this
  });

  @override
  Widget build(BuildContext context) {
    if (submissions.isEmpty) {
      return const Center(child: Text('No results to display.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Total: ${submissions.length} published',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Implement publish all functionality if needed
                },
                icon: const Icon(Icons.publish),
                label: const Text('Publish All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final submission = submissions[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(submission.studentName[0])),
                  title: Text(submission.studentName),
                  subtitle: Text('${submission.marksObtained ?? 0} / ${test.totalMarks}'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
