class Tag {
  const Tag({
    this.id,
    required this.name,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String name;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Tag copyWith({
    String? id,
    String? name,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
