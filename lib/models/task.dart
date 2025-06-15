class Task {
  final int id;
  final String title;
  final String description;
  final int createdBy;
  final String updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdBy: json['created_by'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_by': createdBy,
      'updated_at': updatedAt,
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    int? createdBy,
    String? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}