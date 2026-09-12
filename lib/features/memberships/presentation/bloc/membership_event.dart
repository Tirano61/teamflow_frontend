import '../../domain/entities/membership_role.dart';

sealed class MembershipEvent {
  const MembershipEvent();
}

/// Carga el **directorio** de la organizacion activa (`GET .../members`).
///
/// Solo miembros `ACTIVE`, sin acciones administrativas. Lo pide la pantalla
/// de directorio, disponible para cualquier rol.
///
/// No lleva `organizationId`: la organizacion la resuelve el datasource.
class LoadMemberDirectoryRequested extends MembershipEvent {
  const LoadMemberDirectoryRequested();
}

/// Carga el listado **administrativo** de la organizacion activa
/// (`GET .../members/manage`).
///
/// Miembros `ACTIVE` y `SUSPENDED`. Lo pide la pantalla de administracion,
/// disponible solo para OWNER/ADMIN. Las acciones administrativas solo se
/// aceptan sobre un listado cargado con este evento.
class LoadMemberManagementRequested extends MembershipEvent {
  const LoadMemberManagementRequested();
}

/// El usuario confirmo el cambio de rol de un miembro.
///
/// Solo se emite desde la pantalla administrativa. Tampoco lleva
/// `organizationId`: la organizacion la resuelve el datasource.
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

/// El usuario confirmo la suspension de un miembro (`ACTIVE` -> `SUSPENDED`).
///
/// Solo se emite desde la pantalla administrativa.
class SuspendMemberRequested extends MembershipEvent {
  const SuspendMemberRequested(this.membershipId);

  /// `membershipId` de la fila pulsada, no el id del usuario.
  final String membershipId;
}

/// El usuario confirmo la reactivacion de un miembro
/// (`SUSPENDED` -> `ACTIVE`).
///
/// Solo se emite desde la pantalla administrativa.
class ReactivateMemberRequested extends MembershipEvent {
  const ReactivateMemberRequested(this.membershipId);

  /// `membershipId` de la fila pulsada, no el id del usuario.
  final String membershipId;
}
