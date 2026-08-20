class Application {
  const Application({
    this.id,
    required this.name,
    this.description,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String name;
  final String? description;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Application copyWith({
    String? id,
    String? name,
    String? description,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Application(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}