import '../../../../core/error/result.dart';
import '../repositories/organization_invitation_repository.dart';

class AcceptOrganizationInvitation {
  const AcceptOrganizationInvitation(this._repository);

  final OrganizationInvitationRepository _repository;

  Future<Result<void>> call({required String token}) {
    return _repository.acceptInvitation(token: token);
  }
}
