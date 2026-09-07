import 'invitation_status.dart';

/// Invitacion enviada por la organizacion activa
/// (`GET /organizations/{organizationId}/invitations`).
///
/// Es la vista administrativa de la invitacion: la ve quien invita, no quien
/// recibe. La invitacion recibida se modela aparte como `PendingInvitation` en
/// `user_context`, porque llega en `/me/context` con otros campos (incluye el
/// token de aceptacion, que este endpoint no expone).
class OrganizationInvitation {
  const OrganizationInvitation({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.invitedUser,
    this.expiresAt,
    this.acceptedAt,
    this.createdAt,
  });

  /// `invitationId` del backend: es el id que viaja en el path de cancelar.
  final String id;

  /// Email al que se envio la invitacion.
  ///
  /// Siempre viene, incluso cuando [invitedUser] es null.
  final String email;

  /// `OWNER`, `ADMIN`, `DEVELOPER` o `MEMBER` segun el backend.
  ///
  /// Se guarda como String, no como `OrganizationInvitationRole`: ese enum solo
  /// cubre los roles asignables al crear y aca puede llegar cualquier valor
  /// historico.
  final String role;

  final InvitationStatus status;

  /// Usuario registrado al que se invito.
  ///
  /// Es null en invitaciones legacy, creadas cuando el backend aceptaba invitar
  /// por email a alguien que todavia no tenia cuenta.
  final OrganizationInvitationUser? invitedUser;

  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? createdAt;

  /// Nombre visible del destinatario.
  ///
  /// Cae al email cuando la invitacion no tiene usuario asociado (legacy) o
  /// cuando el usuario no tiene nombre cargado.
  String get recipientName {
    final name = invitedUser?.displayName.trim() ?? '';
    return name.isEmpty ? email.trim() : name;
  }

  /// Email visible del destinatario.
  ///
  /// El `email` de la invitacion manda; el del usuario solo se usa si aquel
  /// llegara vacio.
  String get recipientEmail {
    final invitationEmail = email.trim();
    return invitationEmail.isEmpty
        ? (invitedUser?.email.trim() ?? '')
        : invitationEmail;
  }

  /// La invitacion se puede cancelar.
  ///
  /// Es control visual: la autoridad final es el backend, que responde 409 si
  /// entre medio dejo de estar pendiente.
  bool get isPending => status == InvitationStatus.pending;

  /// Copia con el estado cambiado.
  ///
  /// La usa el bloc para reflejar la cancelacion sin recargar todo el listado:
  /// el backend no devuelve la invitacion actualizada.
  OrganizationInvitation copyWithStatus(InvitationStatus status) {
    return OrganizationInvitation(
      id: id,
      email: email,
      role: role,
      status: status,
      invitedUser: invitedUser,
      expiresAt: expiresAt,
      acceptedAt: acceptedAt,
      createdAt: createdAt,
    );
  }
}

/// Datos publicos del usuario invitado, tal como los anida el backend en
/// `invitedUser`.
class OrganizationInvitationUser {
  const OrganizationInvitationUser({
    required this.id,
    required this.email,
    required this.fullName,
  });

  final String id;
  final String email;
  final String fullName;

  /// Nombre visible del usuario. Cae al email si no tiene nombre cargado.
  String get displayName {
    final trimmedName = fullName.trim();
    return trimmedName.isEmpty ? email.trim() : trimmedName;
  }
}
