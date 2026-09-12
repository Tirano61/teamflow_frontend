import '../../../../core/error/result.dart';
import '../entities/membership.dart';
import '../entities/membership_role.dart';
import '../repositories/membership_repository.dart';

class ChangeMemberRole {
  const ChangeMemberRole(this._repository);

  final MembershipRepository _repository;

  /// Cambia el rol del miembro [membershipId] de la organizacion activa.
  ///
  /// Devuelve la membresia actualizada. El backend es idempotente si el rol
  /// solicitado es el que el miembro ya tiene, y responde 409 si mientras
  /// tanto cambio de rol o dejo de estar `ACTIVE`.
  Future<Result<Membership>> call({
    required String membershipId,
    required MembershipRole role,
  }) {
    return _repository.changeMemberRole(membershipId: membershipId, role: role);
  }
}
