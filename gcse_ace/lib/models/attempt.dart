class Attempt {
  final String id;
  final String userId;
  final String paperId;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final int? score;
  final int totalMarks;
  final Map<String, dynamic> answers;
  final String? paperTitle;
  final String? departmentName;

  const Attempt({
    required this.id,
    required this.userId,
    required this.paperId,
    required this.startedAt,
    this.submittedAt,
    this.score,
    required this.totalMarks,
    required this.answers,
    this.paperTitle,
    this.departmentName,
  });

  bool get isCompleted => submittedAt != null && score != null;

  double get percentage => totalMarks > 0 && score != null ? (score! / totalMarks) * 100 : 0;

  factory Attempt.fromJson(Map<String, dynamic> json) {
    return Attempt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      paperId: json['paper_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      score: json['score'] as int?,
      totalMarks: json['total_marks'] as int,
      answers: json['answers'] as Map<String, dynamic>? ?? {},
      paperTitle: json['papers']?['title'] as String?,
      departmentName: json['papers']?['departments']?['name'] as String?,
    );
  }
}
