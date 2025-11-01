import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExamReviewScreen extends StatefulWidget {
  final String resultId;

  const ExamReviewScreen({super.key, required this.resultId});

  @override
  State<ExamReviewScreen> createState() => _ExamReviewScreenState();
}

class _ExamReviewScreenState extends State<ExamReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _scoreController = TextEditingController();
  final List<String> _strengths = [];
  final List<String> _improvements = [];
  bool _loading = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await FirestoreService().reviewExamResult(
        resultId: widget.resultId,
        finalScore: double.parse(_scoreController.text),
        overallFeedback: _feedbackController.text,
        corrections: {
          'strengths': _strengths,
          'improvements': _improvements,
        },
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Review submitted successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Review Exam'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          if (!_loading)
            IconButton(
              onPressed: _submitReview,
              icon: const Icon(Icons.check),
              tooltip: 'Submit Review',
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('results')
            .doc(widget.resultId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Result not found'));
          }

          final result = snapshot.data!.data() as Map<String, dynamic>;
          final aiScore = result['aiScore'] ?? 0.0;
          final totalMarks = result['totalMarks'] ?? 100;

          if (_scoreController.text.isEmpty) {
            _scoreController.text = aiScore.toString();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Info
                  FutureBuilder<Map<String, dynamic>?>(
                    future: firestoreService.getStudentDetails(result['studentId']),
                    builder: (context, studentSnapshot) {
                      final studentName = studentSnapshot.data?['displayName'] ?? 'Student';
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, color: Color(0xFF1E3A8A)),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'AI Score: ${aiScore.toInt()}/$totalMarks',
                                  style: const TextStyle(color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Final Score
                  const Text(
                    'Final Score',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _scoreController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter final score',
                      suffixText: '/ $totalMarks',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) {
                      final score = double.tryParse(v ?? '');
                      if (score == null) return 'Enter valid score';
                      if (score < 0 || score > totalMarks) {
                        return 'Score must be between 0 and $totalMarks';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Overall Feedback
                  const Text(
                    'Overall Feedback',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _feedbackController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Provide detailed feedback for the student...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Feedback required' : null,
                  ),
                  const SizedBox(height: 24),

                  // Strengths
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Strengths',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showAddDialog('strength'),
                        icon: const Icon(Icons.add_circle, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._strengths.map((s) => _buildListItem(
                      s, Icons.check_circle, const Color(0xFF059669), () {
                    setState(() => _strengths.remove(s));
                  })),
                  const SizedBox(height: 24),

                  // Improvements
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Areas for Improvement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showAddDialog('improvement'),
                        icon: const Icon(Icons.add_circle, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._improvements.map((i) => _buildListItem(
                      i, Icons.lightbulb, const Color(0xFFDC2626), () {
                    setState(() => _improvements.remove(i));
                  })),
                  const SizedBox(height: 40),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _loading ? 'Submitting...' : 'Submit Review',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListItem(
      String text, IconData icon, Color color, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: color))),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.close, size: 20),
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  void _showAddDialog(String type) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${type == 'strength' ? 'Strength' : 'Improvement'}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter ${type}...',
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  if (type == 'strength') {
                    _strengths.add(controller.text.trim());
                  } else {
                    _improvements.add(controller.text.trim());
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}
