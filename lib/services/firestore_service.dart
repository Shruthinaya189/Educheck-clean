import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/class_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a class (Teacher only)
  Future<void> createClass(Map<String, dynamic> classData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore.collection('classes').add({
      ...classData,
      'teacherId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get teacher's classes (real-time)
  Stream<List<ClassModel>> getTeacherClassesStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromFirestore(doc))
            .toList());
  }

  // Get student's enrolled classes (real-time)
  Stream<List<ClassModel>> getStudentClassesStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('classes')
        .where('enrolledStudents', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromFirestore(doc))
            .toList());
  }

  // Join class (Student only)
  Future<void> joinClass(String classCode) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final classQuery = await _firestore
        .collection('classes')
        .where('code', isEqualTo: classCode)
        .limit(1)
        .get();

    if (classQuery.docs.isEmpty) {
      throw Exception('Invalid class code');
    }

    final classDoc = classQuery.docs.first;
    await classDoc.reference.update({
      'enrolledStudents': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create notification for teacher
    await _createNotification(
      userId: classDoc.data()['teacherId'],
      title: 'New Student Joined',
      message: 'A student joined your class: ${classDoc.data()['name']}',
      type: 'student_joined',
      classId: classDoc.id,
    );
  }

  // Upload exam (Teacher only)
  Future<void> uploadExam(String classId, Map<String, dynamic> examData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final examRef = await _firestore.collection('exams').add({
      ...examData,
      'classId': classId,
      'teacherId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Get all enrolled students
    final classDoc = await _firestore.collection('classes').doc(classId).get();
    final enrolledStudents = List<String>.from(classDoc.data()?['enrolledStudents'] ?? []);

    // Notify all students
    for (final studentId in enrolledStudents) {
      await _createNotification(
        userId: studentId,
        title: 'New Exam Posted',
        message: 'New exam: ${examData['title']} in ${classDoc.data()?['name']}',
        type: 'new_exam',
        classId: classId,
        examId: examRef.id,
      );
    }
  }

  // ==================== RESULTS & FEEDBACK ====================
  
  // Upload AI-corrected result (Teacher only)
  Future<String> uploadExamResult({
    required String examId,
    required String studentId,
    required String classId,
    required Map<String, dynamic> aiCorrectionData,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final resultRef = await _firestore.collection('results').add({
      'examId': examId,
      'studentId': studentId,
      'classId': classId,
      'teacherId': userId,
      'aiScore': aiCorrectionData['score'],
      'totalMarks': aiCorrectionData['totalMarks'],
      'aiCorrections': aiCorrectionData['corrections'],
      'status': 'pending_review', // pending_review, reviewed, published
      'teacherReviewed': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Notify student
    await _createNotification(
      userId: studentId,
      title: 'Exam Submitted',
      message: 'Your exam has been submitted and is being evaluated',
      type: 'exam_submitted',
      examId: examId,
    );

    return resultRef.id;
  }

  // Teacher reviews AI result and adds feedback
  Future<void> reviewExamResult({
    required String resultId,
    required double finalScore,
    required String overallFeedback,
    Map<String, dynamic>? corrections,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final resultDoc = await _firestore.collection('results').doc(resultId).get();
    final resultData = resultDoc.data();
    if (resultData == null) throw Exception('Result not found');

    // Update result
    await _firestore.collection('results').doc(resultId).update({
      'finalScore': finalScore,
      'teacherReviewed': true,
      'status': 'reviewed',
      'teacherCorrections': corrections,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create feedback document
    await _firestore.collection('feedback').add({
      'resultId': resultId,
      'examId': resultData['examId'],
      'studentId': resultData['studentId'],
      'teacherId': userId,
      'classId': resultData['classId'],
      'overallFeedback': overallFeedback,
      'finalScore': finalScore,
      'strengths': corrections?['strengths'] ?? [],
      'improvements': corrections?['improvements'] ?? [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Notify student
    await _createNotification(
      userId: resultData['studentId'],
      title: 'Result Reviewed',
      message: 'Your teacher has reviewed your exam. Check your feedback!',
      type: 'result_reviewed',
    );
  }

  // Publish result (make visible to student)
  Future<void> publishResult(String resultId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final resultDoc = await _firestore.collection('results').doc(resultId).get();
    final resultData = resultDoc.data();
    if (resultData == null) throw Exception('Result not found');

    await _firestore.collection('results').doc(resultId).update({
      'status': 'published',
      'publishedAt': FieldValue.serverTimestamp(),
    });

    // Notify student
    await _createNotification(
      userId: resultData['studentId'],
      title: 'Result Published',
      message: 'Your exam result is now available!',
      type: 'result_published',
    );
  }

  // Get student's results (real-time)
  Stream<List<Map<String, dynamic>>> getStudentResultsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('results')
        .where('studentId', isEqualTo: userId)
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // Get teacher's pending reviews (real-time)
  Stream<List<Map<String, dynamic>>> getTeacherPendingReviewsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('results')
        .where('teacherId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending_review')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // Get feedback for a result
  Stream<Map<String, dynamic>?> getFeedbackStream(String resultId) {
    return _firestore
        .collection('feedback')
        .where('resultId', isEqualTo: resultId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty
            ? null
            : {'id': snapshot.docs.first.id, ...snapshot.docs.first.data()});
  }

  // Get exam details
  Future<Map<String, dynamic>?> getExamDetails(String examId) async {
    final doc = await _firestore.collection('exams').doc(examId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  // Get student details
  Future<Map<String, dynamic>?> getStudentDetails(String studentId) async {
    final doc = await _firestore.collection('users').doc(studentId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  // Create notification (FIXED: removed resultId parameter where not needed)
  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? classId,
    String? examId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'classId': classId,
      'examId': examId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user notifications (real-time)
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  // Update class
  Future<void> updateClass(String classId, Map<String, dynamic> updates) async {
    await _firestore.collection('classes').doc(classId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete class (Teacher only)
  Future<void> deleteClass(String classId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Verify ownership
    final classDoc = await _firestore.collection('classes').doc(classId).get();
    if (classDoc.data()?['teacherId'] != userId) {
      throw Exception('Unauthorized');
    }

    await _firestore.collection('classes').doc(classId).delete();
  }

  // ==================== QUERY SYSTEM ====================
  
  // Student raises a query on their result
  Future<void> raiseQuery({
    required String resultId,
    required String queryText,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final resultDoc = await _firestore.collection('results').doc(resultId).get();
    final resultData = resultDoc.data();
    if (resultData == null) throw Exception('Result not found');

    await _firestore.collection('queries').add({
      'resultId': resultId,
      'examId': resultData['examId'],
      'studentId': userId,
      'teacherId': resultData['teacherId'],
      'queryText': queryText,
      'status': 'pending', // pending, resolved
      'response': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Notify teacher
    await _createNotification(
      userId: resultData['teacherId'],
      title: 'New Query Raised',
      message: 'A student has raised a query on an exam result',
      type: 'query_raised',
    );
  }

  // Teacher responds to a query
  Future<void> respondToQuery({
    required String queryId,
    required String response,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final queryDoc = await _firestore.collection('queries').doc(queryId).get();
    final queryData = queryDoc.data();
    if (queryData == null) throw Exception('Query not found');

    await _firestore.collection('queries').doc(queryId).update({
      'response': response,
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    // Notify student
    await _createNotification(
      userId: queryData['studentId'],
      title: 'Query Resolved',
      message: 'Your teacher has responded to your query',
      type: 'query_resolved',
    );
  }

  // Get student's queries (real-time)
  Stream<List<Map<String, dynamic>>> getStudentQueriesStream(String resultId) {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('queries')
        .where('resultId', isEqualTo: resultId)
        .where('studentId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // Get teacher's pending queries (real-time)
  Stream<List<Map<String, dynamic>>> getTeacherPendingQueriesStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('queries')
        .where('teacherId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // ==================== EXAM MANAGEMENT ====================
  
  // Create exam (Teacher only)
  Future<String> createExam({
    required String classId,
    required String title,
    required String description,
    required DateTime examDate,
    required int duration, // in minutes
    required int totalMarks,
    required bool allowStudentUpload, // true = students upload, false = teacher uploads
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final examRef = await _firestore.collection('exams').add({
      'classId': classId,
      'teacherId': userId,
      'title': title,
      'description': description,
      'examDate': Timestamp.fromDate(examDate),
      'duration': duration,
      'totalMarks': totalMarks,
      'allowStudentUpload': allowStudentUpload,
      'questionPaperUrl': null,
      'status': 'draft', // draft, published, completed
      'createdAt': FieldValue.serverTimestamp(),
    });

    return examRef.id;
  }

  // Upload question paper (Teacher only)
  Future<void> uploadQuestionPaper({
    required String examId,
    required String questionPaperUrl,
  }) async {
    await _firestore.collection('exams').doc(examId).update({
      'questionPaperUrl': questionPaperUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Publish exam (notify students)
  Future<void> publishExam(String examId) async {
    final examDoc = await _firestore.collection('exams').doc(examId).get();
    final examData = examDoc.data();
    if (examData == null) throw Exception('Exam not found');

    await _firestore.collection('exams').doc(examId).update({
      'status': 'published',
      'publishedAt': FieldValue.serverTimestamp(),
    });

    // Get all enrolled students
    final classDoc = await _firestore.collection('classes').doc(examData['classId']).get();
    final enrolledStudents = List<String>.from(classDoc.data()?['enrolledStudents'] ?? []);

    // Notify all students
    for (final studentId in enrolledStudents) {
      await _createNotification(
        userId: studentId,
        title: 'New Exam Published',
        message: 'Exam: ${examData['title']}',
        type: 'exam_published',
        examId: examId,
      );
    }
  }

  // Get exams for a class (real-time)
  Stream<List<Map<String, dynamic>>> getClassExamsStream(String classId) {
    return _firestore
        .collection('exams')
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: 'published')
        .orderBy('examDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // Student submits answer sheet (if allowed)
  Future<void> submitAnswerSheet({
    required String examId,
    required String classId,
    required List<String> answerSheetUrls, // URLs of uploaded images/PDF
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore.collection('submissions').add({
      'examId': examId,
      'classId': classId,
      'studentId': userId,
      'answerSheetUrls': answerSheetUrls,
      'status': 'submitted', // submitted, scanned, evaluated
      'submittedAt': FieldValue.serverTimestamp(),
    });

    // Notify teacher
    final examDoc = await _firestore.collection('exams').doc(examId).get();
    final teacherId = examDoc.data()?['teacherId'];
    
    if (teacherId != null) {
      await _createNotification(
        userId: teacherId,
        title: 'Answer Sheet Submitted',
        message: 'A student submitted their answer sheet',
        type: 'submission_received',
        examId: examId,
      );
    }
  }

  // Teacher uploads all answer sheets (if teacher upload mode)
  Future<void> uploadAnswerSheetsBatch({
    required String examId,
    required List<Map<String, dynamic>> submissions, // [{studentId, urls}]
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    for (final submission in submissions) {
      await _firestore.collection('submissions').add({
        'examId': examId,
        'studentId': submission['studentId'],
        'teacherId': userId,
        'answerSheetUrls': submission['urls'],
        'status': 'uploaded_by_teacher',
        'uploadedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // PLACEHOLDER: Integration point for scanning module
  Future<Map<String, dynamic>> scanAnswerSheet({
    required String submissionId,
    required List<String> imageUrls,
  }) async {
    // TODO: Integrate your scanning module here
    // This is where you'll call your AI correction service
    
    // For now, return a mock result
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing
    
    return {
      'score': 85.0,
      'totalMarks': 100.0,
      'corrections': [
        {'questionNo': 1, 'marks': 10, 'comment': 'Correct'},
        {'questionNo': 2, 'marks': 8, 'comment': 'Minor mistake in step 3'},
      ],
    };
  }
}
