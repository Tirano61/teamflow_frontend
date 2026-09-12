/// Rol asignable a un miembro existente mediante
/// `PATCH /organizations/{organizationId}/members/{membershipId}/role`.
///
/// `OWNER` no esta en el enum a proposito: el backend lo rechaza con 400 y la
/// transferencia de ownership es un flujo aparte que todavia no existe. El rol
/// actual de un miembro sigue viajando como `String` en `Membership.role`
/// porque puede ser `OWNER`; este enum modela solo lo que se puede enviar.
///
/// Los helpers estaticos replican las reglas de permisos del backend para
/// decidir que acciones se pintan. Son control visual: la autoridad final es
/// el backend, que responde 403 si el rol no alcanza.
enum MembershipRole {
  member('MEMBER', 'Miembro'),
  developer('DEVELOPER', 'Developer'),
  admin('ADMIN', 'Administrador');

  const MembershipRole(this.apiValue, this.label);

  /// Valor exacto que espera el backend en el body.
  final String apiValue;

  /// Texto visible en la UI.
  final String label;

  /// Rol de membresia que el backend nunca deja modificar desde este endpoint,
  /// sin importar quien haga el request.
  static const String ownerApiValue = 'OWNER';

  /// El rol asignable equivalente a [role], o `null` si no lo es.
  ///
  /// Devuelve `null` para `OWNER`, para un texto vacio y para cualquier rol
  /// que este frontend no conozca.
  static MembershipRole? fromApiValue(String role) {
    final normalized = role.trim().toUpperCase();

    for (final value in values) {
      if (value.apiValue == normalized) {
        return value;
      }
    }

    return null;
  }

  /// Roles que [actorRole] puede asignar en la organizacion activa.
  ///
  /// - `OWNER`: `ADMIN`, `DEVELOPER` y `MEMBER`.
  /// - `ADMIN`: `DEVELOPER` y `MEMBER`; no puede crear otros `ADMIN`.
  /// - Cualquier otro rol: ninguno, no puede administrar roles.
  static List<MembershipRole> assignableBy(String actorRole) {
    final normalized = actorRole.trim().toUpperCase();

    if (normalized == ownerApiValue) {
      return values;
    }

    if (normalized == admin.apiValue) {
      return const [member, developer];
    }

    return const [];
  }

  /// [actorRole] puede cambiar el rol de un miembro cuyo rol actual es
  /// [targetRole].
  ///
  /// En el backend el conjunto de roles modificables coincide con el de roles
  /// asignables para OWNER y para ADMIN, asi que alcanza con una regla: se
  /// puede editar a quien tiene un rol que ademas se podria volver a asignar.
  /// `OWNER` queda fuera porque no es un rol asignable.
  static bool canChangeRoleOf({
    required String actorRole,
    required String targetRole,
  }) {
    final target = fromApiValue(targetRole);
    if (target == null) {
      return false;
    }

    return assignableBy(actorRole).contains(target);
  }
}
