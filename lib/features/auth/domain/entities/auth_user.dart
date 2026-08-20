class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.roles = const [],
  });

  final String id;
  final String email;
  final String fullName;
  final List<String> roles;

  bool get isDeveloper =>
      roles.map((role) => role.trim().toLowerCase()).contains('developer');
}
