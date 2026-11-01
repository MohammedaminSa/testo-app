class Course {
  final String id;
  final String departmentId;
  final String name;
  final String? code;
  final String? description;

  const Course({
    required this.id,
    required this.departmentId,
    required this.name,
    this.code,
    this.description,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      departmentId: json['department_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'department_id': departmentId,
      'name': name,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
    };
  }
}

