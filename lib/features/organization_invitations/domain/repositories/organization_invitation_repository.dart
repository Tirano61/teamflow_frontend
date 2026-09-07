import '../../../../core/error/result.dart';
import '../entities/organization_invitation_role.dart';

abstract class OrganizationInvitationRepository {
  /// Acepta una invitacion pendiente
  /// (`POST /organization-invitations/{token}/accept`).
  ///
  /// La invitacion se identifica por el `token` que ya viaja en la
  /// `PendingInvitation` de `GET /me/context`: no hace falta una entidad
  /// propia de invitacion en esta feature.
  Future<Result<void>> acceptInvitation({required String token});

  /// Invita a un usuario registrado a la organizacion activa
  /// (`POST /organizations/{organizationId}/invitations`).
  ///
  /// El destinatario viaja como `userId`, nunca como email escrito a mano. La
  /// organizacion la resuelve el datasource contra `OrganizationContext`: no
  /// se pasa desde la UI.
  ///
  /// No devuelve la invitacion creada: la membresia no existe hasta que el
  /// invitado acepta, asi que no hay nada que refrescar en pantalla.
  Future<Result<void>> createInvitation({
    required String userId,
    required OrganizationInvitationRole role,
  });
}
