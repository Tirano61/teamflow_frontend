/// Usuario autenticado tal como lo describe `GET /me/context`.
class ContextUser {
  const ContextUser({
    required this.id,
    required this.email,
    required this.fullName,
  });

  final String id;
  final String email;
  final String fullName;
}
