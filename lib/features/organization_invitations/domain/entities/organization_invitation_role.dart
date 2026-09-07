/// Rol que se puede asignar al crear una invitacion.
///
/// El backend acepta `MEMBER`, `DEVELOPER` y `ADMIN` en
/// `POST /organizations/{organizationId}/invitations`. `OWNER` no es
/// asignable: lo obtiene unicamente quien crea la organizacion, asi que no
/// existe como opcion en este enum.
enum OrganizationInvitationRole {
  member('MEMBER', 'Miembro'),
  developer('DEVELOPER', 'Developer'),
  admin('ADMIN', 'Administrador');

  const OrganizationInvitationRole(this.apiValue, this.label);

  /// Valor exacto que espera el backend en el body.
  final String apiValue;

  /// Texto visible en la UI.
  final String label;
}
