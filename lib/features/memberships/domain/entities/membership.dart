/// Miembro de una organizacion (`GET /organizations/{organizationId}/members`).
///
/// Solo modela lo que el backend devuelve hoy: la membership (`id`, `role`,
/// `status`, `joinedAt`) y los datos publicos del usuario asociado.
class Membership {
  const Membership({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.joinedAt,
  });

  /// Id de la membership, no del usuario.
  final String id;

  final String userId;
  final String fullName;
  final String email;

  /// `OWNER`, `ADMIN`, `DEVELOPER` o `MEMBER` segun el backend.
  final String role;

  /// `ACTIVE` o `SUSPENDED` segun el backend.
  final String status;

  final DateTime? joinedAt;

  /// Nombre visible del miembro.
  ///
  /// Cae al email cuando el usuario no tiene nombre cargado. Puede quedar
  /// vacio: el texto de reemplazo lo decide cada pantalla.
  String get displayName {
    final trimmedName = fullName.trim();
    return trimmedName.isEmpty ? email.trim() : trimmedName;
  }
}
