class Department {
  final String id;
  final String name;
  final String slug;
  final String? description;

  const Department({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
    );
  }
}
