import '../../domain/entities/membership_role.dart';

sealed class MembershipEvent {
  const MembershipEvent();
}

/// Carga los miembros de la organizacion activa.
///
/// No lleva `organizationId`: la organizacion la resuelve el datasource.
class LoadOrganizationMembersEvent extends MembershipEvent {
  const LoadOrganizationMembersEvent();
}

/// El usuario confirmo el cambio de rol de un miembro.
///
/// Tampoco lleva `organizationId`: la organizacion la resuelve el datasource.
class ChangeMemberRoleRequested extends MembershipEvent {
  const ChangeMemberRoleRequested({
    required this.membershipId,
    required this.role,
  });

  /// `membershipId` de la fila pulsada, no el id del usuario.
  final String membershipId;

  /// Rol nuevo. `OWNER` no existe como opcion: no es asignable.
  final MembershipRole role;
}
