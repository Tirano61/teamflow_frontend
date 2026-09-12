import '../../../../core/error/result.dart';
import '../entities/membership.dart';
import '../repositories/membership_repository.dart';

/// Directorio de miembros de la organizacion activa (`GET .../members`).
///
/// Devuelve solo los miembros `ACTIVE` y esta disponible para cualquier rol.
/// La administracion usa [GetOrganizationMembersForManagement].
class GetOrganizationMembers {
  const GetOrganizationMembers(this._repository);

  final MembershipRepository _repository;

  Future<Result<List<Membership>>> call() {
    return _repository.getOrganizationMembers();
  }
}
