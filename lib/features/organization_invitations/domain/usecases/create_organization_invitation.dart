import '../../../../core/error/result.dart';
import '../entities/organization_invitation_role.dart';
import '../repositories/organization_invitation_repository.dart';

class CreateOrganizationInvitation {
  const CreateOrganizationInvitation(this._repository);

  final OrganizationInvitationRepository _repository;

  /// Invita al usuario [userId] con el rol [role] a la organizacion activa.
  ///
  /// El `organizationId` no es parametro: lo resuelve el datasource contra
  /// `OrganizationContext`.
  Future<Result<void>> call({
    required String userId,
    required OrganizationInvitationRole role,
  }) {
    return _repository.createInvitation(userId: userId, role: role);
  }
}
