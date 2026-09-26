import '../../../../core/error/result.dart';
import '../entities/membership.dart';
import '../repositories/membership_repository.dart';

class LeaveOrganization {
  const LeaveOrganization(this._repository);

  final MembershipRepository _repository;

  /// El usuario autenticado abandona la organizacion activa.
  ///
  /// Devuelve su membresia con `status = LEFT`. La lista de organizaciones no
  /// se corrige aca: quien llama debe recargar `/me/context`, que es la fuente
  /// de verdad de la pertenencia.
  Future<Result<Membership>> call() {
    return _repository.leaveOrganization();
  }
}
