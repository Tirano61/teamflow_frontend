import '../../../../core/error/result.dart';
import '../entities/membership.dart';

abstract class MembershipRepository {
  /// Miembros de la organizacion activa.
  ///
  /// El `organizationId` no viaja como parametro: lo resuelve el datasource
  /// contra `OrganizationContext` en cada request.
  Future<Result<List<Membership>>> getOrganizationMembers();
}
