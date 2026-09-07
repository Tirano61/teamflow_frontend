/// Estado de una invitacion segun el backend
/// (`GET /organizations/{organizationId}/invitations`).
///
/// Es el estado del recurso, no el de una request: el estado de los flujos de
/// pantalla vive en `OrganizationInvitationState`.
///
/// [unknown] cubre cualquier valor que el backend agregue mas adelante: la
/// pantalla lo pinta como estado desconocido en vez de romper el listado.
enum InvitationStatus {
  pending('PENDING', 'Pendiente'),
  accepted('ACCEPTED', 'Aceptada'),
  expired('EXPIRED', 'Vencida'),
  cancelled('CANCELLED', 'Cancelada'),
  unknown('', 'Desconocida');

  const InvitationStatus(this.apiValue, this.label);

  /// Valor exacto que devuelve el backend.
  final String apiValue;

  /// Texto visible en la UI.
  final String label;

  /// Traduce el `status` del backend. Devuelve [unknown] si no coincide con
  /// ninguno de los estados conocidos.
  static InvitationStatus fromApiValue(String? value) {
    final normalized = value?.trim().toUpperCase() ?? '';
    if (normalized.isEmpty) {
      return InvitationStatus.unknown;
    }

    for (final status in InvitationStatus.values) {
      if (status.apiValue == normalized) {
        return status;
      }
    }

    return InvitationStatus.unknown;
  }
}
