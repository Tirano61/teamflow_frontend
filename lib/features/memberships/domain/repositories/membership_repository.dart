import '../../../../core/error/result.dart';
import '../entities/membership.dart';
import '../entities/membership_role.dart';

abstract class MembershipRepository {
  /// Miembros de la organizacion activa.
  ///
  /// El `organizationId` no viaja como parametro: lo resuelve el datasource
  /// contra `OrganizationContext` en cada request.
  Future<Result<List<Membership>>> getOrganizationMembers();

  /// Cambia el rol del miembro [membershipId] de la organizacion activa
  /// (`PATCH .../members/{membershipId}/role`).
  ///
  /// Devuelve la membresia ya actualizada: quien llama puede reemplazar la
  /// fila sin recargar el listado. La organizacion la resuelve el datasource
  /// contra `OrganizationContext`: no se pasa desde la UI.
  ///
  /// Solo OWNER/ADMIN pueden usarlo y `OWNER` no es un rol asignable; el
  /// backend responde 403 si las reglas de rol no se cumplen.
  Future<Result<Membership>> changeMemberRole({
    required String membershipId,
    required MembershipRole role,
  });
}
