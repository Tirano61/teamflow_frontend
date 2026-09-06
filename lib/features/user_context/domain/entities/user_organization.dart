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

  /// Nombre visible de la organizacion.
  ///
  /// Cae al slug cuando la organizacion no tiene nombre cargado. Puede quedar
  /// vacio: el texto de reemplazo lo decide cada pantalla.
  String get displayName {
    final trimmedName = name.trim();
    return trimmedName.isEmpty ? slug.trim() : trimmedName;
  }
}
