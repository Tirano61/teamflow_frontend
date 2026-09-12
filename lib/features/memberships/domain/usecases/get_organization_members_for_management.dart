import '../../../../core/error/result.dart';
import '../entities/membership.dart';
import '../repositories/membership_repository.dart';

/// Listado administrativo de la organizacion activa
/// (`GET .../members/manage`).
///
/// Devuelve miembros `ACTIVE` y `SUSPENDED`. Es el listado que alimenta la
/// pantalla de administracion; el directorio usa [GetOrganizationMembers].
class GetOrganizationMembersForManagement {
  const GetOrganizationMembersForManagement(this._repository);

  final MembershipRepository _repository;

  Future<Result<List<Membership>>> call() {
    return _repository.getOrganizationMembersForManagement();
  }
}
