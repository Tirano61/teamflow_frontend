sealed class OrganizationInvitationEvent {
  const OrganizationInvitationEvent();
}

/// El usuario pulso `Aceptar` en una invitacion pendiente.
class AcceptOrganizationInvitationRequested extends OrganizationInvitationEvent {
  const AcceptOrganizationInvitationRequested(this.token);

  /// Token de la `PendingInvitation` que viene en `GET /me/context`.
  final String token;
}
