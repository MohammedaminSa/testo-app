class StudyMaterial {
  final String id;
  final String departmentId;
  final String? courseId;
  final String? courseName;
  final String title;
  final String content;
  final String? url;

  const StudyMaterial({
    required this.id,
    required this.departmentId,
    this.courseId,
    this.courseName,
    required this.title,
    required this.content,
    this.url,
  });

  bool get isPdf =>
      url != null &&
      (url!.toLowerCase().endsWith('.pdf') || url!.toLowerCase().contains('.pdf'));

  String get displayName =>
      (courseName != null && courseName!.trim().isNotEmpty) ? courseName! : title;

  factory StudyMaterial.fromJson(Map<String, dynamic> json) {
    return StudyMaterial(
      id: json['id'] as String,
      departmentId: json['department_id'] as String,
      courseId: json['course_id'] as String?,
      courseName: json['course_name'] as String?,
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'department_id': departmentId,
      if (courseId != null) 'course_id': courseId,
      if (courseName != null) 'course_name': courseName,
      'title': title,
      'content': content,
      if (url != null) 'url': url,
    };
  }
}
