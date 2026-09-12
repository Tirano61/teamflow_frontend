import '../../../../core/error/result.dart';
import '../entities/membership.dart';
import '../repositories/membership_repository.dart';

class ReactivateMember {
  const ReactivateMember(this._repository);

  final MembershipRepository _repository;

  /// Reactiva al miembro [membershipId] de la organizacion activa.
  ///
  /// Devuelve la membresia actualizada con `status = ACTIVE` y el mismo rol
  /// que tenia antes de la suspension. El backend responde 409 si ya estaba
  /// activa y 403 si el requester no alcanza a ese miembro o intenta
  /// reactivarse a si mismo.
  Future<Result<Membership>> call({required String membershipId}) {
    return _repository.reactivateMember(membershipId: membershipId);
  }
}
