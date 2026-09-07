import '../../../../core/error/result.dart';
import '../entities/organization_invitation.dart';
import '../repositories/organization_invitation_repository.dart';

class GetOrganizationInvitations {
  const GetOrganizationInvitations(this._repository);

  final OrganizationInvitationRepository _repository;

  /// Invitaciones enviadas por la organizacion activa, en todos sus estados.
  ///
  /// El `organizationId` no es parametro: lo resuelve el datasource contra
  /// `OrganizationContext`.
  Future<Result<List<OrganizationInvitation>>> call() {
    return _repository.getInvitations();
  }
}
