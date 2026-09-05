/// Organizacion a la que pertenece el usuario autenticado.
class UserOrganization {
  const UserOrganization({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    this.joinedAt,
  });

  final String id;
  final String name;
  final String slug;
  final String role;
  final DateTime? joinedAt;
}
