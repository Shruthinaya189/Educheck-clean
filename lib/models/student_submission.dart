class StudentSubmission {
  final String id;
  final String testId;
  final String studentId;
  final String studentName;
  final String? answerSheetUrl;
  final int? marksObtained;
  final bool isAbsent;
  final bool isCorrected;
  final bool isPublished;
  final String? query;
  final String? queryResponse;

  StudentSubmission({
    required this.id,
    required this.testId,
    required this.studentId,
    required this.studentName,
    this.answerSheetUrl,
    this.marksObtained,
    this.isAbsent = false,
    this.isCorrected = false,
    this.isPublished = false,
    this.query,
    this.queryResponse,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'testId': testId,
    'studentId': studentId,
    'studentName': studentName,
    'answerSheetUrl': answerSheetUrl,
    'marksObtained': marksObtained,
    'isAbsent': isAbsent,
    'isCorrected': isCorrected,
    'isPublished': isPublished,
    'query': query,
    'queryResponse': queryResponse,
  };

  factory StudentSubmission.fromJson(Map<String, dynamic> json) => StudentSubmission(
    id: json['id'],
    testId: json['testId'],
    studentId: json['studentId'],
    studentName: json['studentName'],
    answerSheetUrl: json['answerSheetUrl'],
    marksObtained: json['marksObtained'],
    isAbsent: json['isAbsent'] ?? false,
    isCorrected: json['isCorrected'] ?? false,
    isPublished: json['isPublished'] ?? false,
    query: json['query'],
    queryResponse: json['queryResponse'],
  );

  StudentSubmission copyWith({
    int? marksObtained,
    bool? isAbsent,
    bool? isCorrected,
    bool? isPublished,
    String? answerSheetUrl,
    String? query,
    String? queryResponse,
  }) {
    return StudentSubmission(
      id: id,
      testId: testId,
      studentId: studentId,
      studentName: studentName,
      answerSheetUrl: answerSheetUrl ?? this.answerSheetUrl,
      marksObtained: marksObtained ?? this.marksObtained,
      isAbsent: isAbsent ?? this.isAbsent,
      isCorrected: isCorrected ?? this.isCorrected,
      isPublished: isPublished ?? this.isPublished,
      query: query ?? this.query,
      queryResponse: queryResponse ?? this.queryResponse,
    );
  }
}
