import 'membership_status.dart';

/// Miembro de una organizacion.
///
/// Mismo contrato en el directorio (`GET /organizations/{organizationId}/members`),
/// en el listado administrativo (`GET .../members/manage`) y en las respuestas
/// de cambio de rol, suspension y reactivacion.
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

  /// `ACTIVE` o `SUSPENDED` tal como lo devuelve el backend.
  ///
  /// Se conserva el texto crudo; [statusValue] es la lectura tipada.
  final String status;

  final DateTime? joinedAt;

  /// [status] interpretado. `MembershipStatus.unknown` si el backend
  /// devolviera un estado que este frontend todavia no conoce.
  MembershipStatus get statusValue => MembershipStatus.fromApiValue(status);

  /// El miembro participa hoy en la organizacion.
  bool get isActive => statusValue == MembershipStatus.active;

  /// El miembro sigue perteneciendo a la organizacion pero perdio el acceso
  /// hasta que se lo reactive. Solo aparece en el listado administrativo.
  bool get isSuspended => statusValue == MembershipStatus.suspended;

  /// Nombre visible del miembro.
  ///
  /// Cae al email cuando el usuario no tiene nombre cargado. Puede quedar
  /// vacio: el texto de reemplazo lo decide cada pantalla.
  String get displayName {
    final trimmedName = fullName.trim();
    return trimmedName.isEmpty ? email.trim() : trimmedName;
  }
}
