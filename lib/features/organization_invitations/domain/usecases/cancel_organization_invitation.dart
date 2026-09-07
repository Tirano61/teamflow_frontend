import '../../../../core/error/result.dart';
import '../repositories/organization_invitation_repository.dart';

class CancelOrganizationInvitation {
  const CancelOrganizationInvitation(this._repository);

  final OrganizationInvitationRepository _repository;

  /// Cancela la invitacion [invitationId] de la organizacion activa.
  ///
  /// Solo se puede cancelar una invitacion `PENDING`; el backend responde 409
  /// si cambio de estado entre el listado y la accion.
  Future<Result<void>> call({required String invitationId}) {
    return _repository.cancelInvitation(invitationId: invitationId);
  }
}
