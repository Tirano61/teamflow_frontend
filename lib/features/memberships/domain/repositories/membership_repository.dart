import '../../../../core/error/result.dart';
import '../entities/membership.dart';
import '../entities/membership_role.dart';

abstract class MembershipRepository {
  /// Directorio de miembros de la organizacion activa
  /// (`GET .../members`).
  ///
  /// Devuelve solo los miembros `ACTIVE` y esta disponible para cualquier rol
  /// con membresia activa. El `organizationId` no viaja como parametro: lo
  /// resuelve el datasource contra `OrganizationContext` en cada request.
  Future<Result<List<Membership>>> getOrganizationMembers();

  /// Listado administrativo de la organizacion activa
  /// (`GET .../members/manage`).
  ///
  /// Devuelve los miembros `ACTIVE` y `SUSPENDED`. Solo OWNER/ADMIN pueden
  /// usarlo; el backend responde 403 al resto de los roles.
  Future<Result<List<Membership>>> getOrganizationMembersForManagement();

  /// Cambia el rol del miembro [membershipId] de la organizacion activa
  /// (`PATCH .../members/{membershipId}/role`).
  ///
  /// Devuelve la membresia ya actualizada: quien llama puede reemplazar la
  /// fila sin recargar el listado. La organizacion la resuelve el datasource
  /// contra `OrganizationContext`: no se pasa desde la UI.
  ///
  /// Solo OWNER/ADMIN pueden usarlo y `OWNER` no es un rol asignable; el
  /// backend responde 403 si las reglas de rol no se cumplen y 409 si el
  /// miembro no esta `ACTIVE`.
  Future<Result<Membership>> changeMemberRole({
    required String membershipId,
    required MembershipRole role,
  });

  /// Suspende al miembro [membershipId] de la organizacion activa
  /// (`POST .../members/{membershipId}/suspend`).
  ///
  /// Cambia solo el `status` a `SUSPENDED` y devuelve la membresia
  /// actualizada. El miembro sigue perteneciendo a la organizacion, pero
  /// pierde el acceso hasta que se lo reactive.
  Future<Result<Membership>> suspendMember({required String membershipId});

  /// Reactiva al miembro [membershipId] de la organizacion activa
  /// (`POST .../members/{membershipId}/reactivate`).
  ///
  /// Cambia solo el `status` a `ACTIVE` conservando el rol que el miembro
  /// tenia antes de la suspension.
  Future<Result<Membership>> reactivateMember({required String membershipId});
}
