class DiscussionAssignedDeveloper {
  const DiscussionAssignedDeveloper({required this.id, required this.fullName});

  final String id;
  final String fullName;

  DiscussionAssignedDeveloper copyWith({String? id, String? fullName}) {
    return DiscussionAssignedDeveloper(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
    );
  }
}

class AssignableDeveloper {
  const AssignableDeveloper({
    required this.id,
    required this.fullName,
    this.email,
  });

  final String id;
  final String fullName;
  final String? email;

  AssignableDeveloper copyWith({String? id, String? fullName, String? email}) {
    return AssignableDeveloper(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
    );
  }
}