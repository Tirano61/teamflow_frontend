/// Invitacion pendiente de aceptar por el usuario autenticado.
///
/// En este paso solo se transporta: aceptar/rechazar se implementa despues.
class PendingInvitation {
  const PendingInvitation({
    required this.invitationId,
    required this.organizationId,
    required this.organizationName,
    required this.organizationSlug,
    required this.role,
    required this.token,
    this.expiresAt,
  });

  final String invitationId;
  final String organizationId;
  final String organizationName;
  final String organizationSlug;
  final String role;
  final String token;
  final DateTime? expiresAt;
}
