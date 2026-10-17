class StudyMaterial {
  final String id;
  final String departmentId;
  final String title;
  final String content;
  final String? url;

  const StudyMaterial({
    required this.id,
    required this.departmentId,
    required this.title,
    required this.content,
    this.url,
  });

  factory StudyMaterial.fromJson(Map<String, dynamic> json) {
    return StudyMaterial(
      id: json['id'] as String,
      departmentId: json['department_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      url: json['url'] as String?,
    );
  }
}
