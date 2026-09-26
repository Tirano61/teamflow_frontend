/// Estado de una Membership segun el backend (`status`).
///
/// Es el estado del recurso, no el de una request: el estado de los flujos de
/// pantalla vive en `MembershipState`.
///
/// El directorio (`GET .../members`) devuelve solo [active]; el listado
/// administrativo (`GET .../members/manage`) devuelve [active] y [suspended].
/// Ninguno de los dos devuelve [left]: solo llega en la respuesta de
/// `POST /organizations/{organizationId}/leave`, con la membresia propia ya
/// abandonada.
///
/// [unknown] cubre cualquier valor que el backend agregue mas adelante: la
/// pantalla lo pinta como estado desconocido en vez de romper el listado.
enum MembershipStatus {
  active('ACTIVE', 'Activo'),
  suspended('SUSPENDED', 'Suspendido'),

  /// El propio usuario abandono voluntariamente la organizacion. Pierde el
  /// acceso y solo vuelve a `ACTIVE` aceptando una nueva invitacion.
  left('LEFT', 'Abandono'),
  unknown('', 'Desconocido');

  const MembershipStatus(this.apiValue, this.label);

  /// Valor exacto que devuelve el backend.
  final String apiValue;

  /// Texto visible en la UI.
  final String label;

  /// Traduce el `status` del backend. Devuelve [unknown] si no coincide con
  /// ninguno de los estados conocidos.
  static MembershipStatus fromApiValue(String? value) {
    final normalized = value?.trim().toUpperCase() ?? '';
    if (normalized.isEmpty) {
      return MembershipStatus.unknown;
    }

    for (final status in MembershipStatus.values) {
      if (status.apiValue == normalized) {
        return status;
      }
    }

    return MembershipStatus.unknown;
  }
}
