class Paper {
  final String id;
  final String departmentId;
  final String title;
  final int year;
  final int durationMinutes;
  final int totalMarks;

  const Paper({
    required this.id,
    required this.departmentId,
    required this.title,
    required this.year,
    required this.durationMinutes,
    required this.totalMarks,
  });

  factory Paper.fromJson(Map<String, dynamic> json) {
    return Paper(
      id: json['id'] as String,
      departmentId: json['department_id'] as String,
      title: json['title'] as String,
      year: json['year'] as int,
      durationMinutes: json['duration_minutes'] as int,
      totalMarks: json['total_marks'] as int,
    );
  }
}
