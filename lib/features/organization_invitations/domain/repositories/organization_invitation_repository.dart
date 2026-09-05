import '../../../../core/error/result.dart';

abstract class OrganizationInvitationRepository {
  /// Acepta una invitacion pendiente
  /// (`POST /organization-invitations/{token}/accept`).
  ///
  /// La invitacion se identifica por el `token` que ya viaja en la
  /// `PendingInvitation` de `GET /me/context`: no hace falta una entidad
  /// propia de invitacion en esta feature.
  Future<Result<void>> acceptInvitation({required String token});
}
