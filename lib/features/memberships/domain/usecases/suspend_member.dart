import '../../../../core/error/result.dart';
import '../entities/membership.dart';
import '../repositories/membership_repository.dart';

class SuspendMember {
  const SuspendMember(this._repository);

  final MembershipRepository _repository;

  /// Suspende al miembro [membershipId] de la organizacion activa.
  ///
  /// Devuelve la membresia actualizada con `status = SUSPENDED`. El backend
  /// responde 409 si ya estaba suspendido y 403 si el requester no alcanza a
  /// ese miembro o intenta suspenderse a si mismo.
  Future<Result<Membership>> call({required String membershipId}) {
    return _repository.suspendMember(membershipId: membershipId);
  }
}
