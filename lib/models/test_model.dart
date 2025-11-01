class TestModel {
  final int id;
  final int classId;
  final String title;
  final String? description;
  final int maxMarks;
  final DateTime createdAt;

  TestModel({
    required this.id,
    required this.classId,
    required this.title,
    this.description,
    required this.maxMarks,
    required this.createdAt,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'],
      classId: json['class_id'],
      title: json['title'],
      description: json['description'],
      maxMarks: json['max_marks'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
