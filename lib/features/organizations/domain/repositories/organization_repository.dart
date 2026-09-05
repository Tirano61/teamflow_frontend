import '../../../../core/error/result.dart';
import '../entities/organization.dart';

abstract class OrganizationRepository {
  /// Crea una organizacion (`POST /organizations`).
  ///
  /// El usuario autenticado queda como `OWNER` de la organizacion creada.
  Future<Result<Organization>> createOrganization({required String name});
}
