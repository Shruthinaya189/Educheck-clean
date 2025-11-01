class StudentSubmission {
  final String? id;
  final String? studentId;
  final String? studentName;
  final String? answerSheetUrl;
  final int? marksObtained;
  final bool? isAbsent;
  final bool? isCorrected;
  final bool? isPublished;
  final String? query;
  final String? queryResponse;

  StudentSubmission({
    this.id,
    this.studentId,
    this.studentName,
    this.answerSheetUrl,
    this.marksObtained,
    this.isAbsent,
    this.isCorrected,
    this.isPublished,
    this.query,
    this.queryResponse,
  });

  StudentSubmission copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? answerSheetUrl,
    int? marksObtained,
    bool? isAbsent,
    bool? isCorrected,
    bool? isPublished,
    String? query,
    String? queryResponse,
  }) {
    return StudentSubmission(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
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