class Paper {
  final String id;
  final String departmentId;
  final String examType; // 'mock' or 'exit_exam'
  final String title;
  final int year;
  final int durationMinutes;
  final int totalMarks;

  const Paper({
    required this.id,
    required this.departmentId,
    this.examType = 'mock',
    required this.title,
    required this.year,
    required this.durationMinutes,
    required this.totalMarks,
  });

  bool get isExitExam => examType == 'exit_exam';
  bool get isMockExam => examType == 'mock';
  String get examTypeDisplay => isExitExam ? 'Exit Exam' : 'Mock Exam';

  factory Paper.fromJson(Map<String, dynamic> json) {
    return Paper(
      id: json['id'] as String,
      departmentId: json['department_id'] as String,
      examType: (json['exam_type'] as String?) ?? 'mock',
      title: json['title'] as String,
      year: json['year'] as int,
      durationMinutes: json['duration_minutes'] as int,
      totalMarks: json['total_marks'] as int,
    );
  }
}
