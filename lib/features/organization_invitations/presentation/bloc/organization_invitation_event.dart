import '../../../users/domain/entities/user_search_result.dart';
import '../../domain/entities/organization_invitation_role.dart';

sealed class OrganizationInvitationEvent {
  const OrganizationInvitationEvent();
}

/// El usuario pulso `Aceptar` en una invitacion pendiente.
class AcceptOrganizationInvitationRequested
    extends OrganizationInvitationEvent {
  const AcceptOrganizationInvitationRequested(this.token);

  /// Token de la `PendingInvitation` que viene en `GET /me/context`.
  final String token;
}

/// Cambio el texto del buscador `Buscar usuario`.
///
/// Se emite en cada tecla: el debounce y el minimo de caracteres los resuelve
/// el bloc, no el widget.
class InvitationUserSearchQueryChanged extends OrganizationInvitationEvent {
  const InvitationUserSearchQueryChanged(this.query);

  final String query;
}

/// El usuario eligio explicitamente un resultado de la busqueda.
///
/// Es el unico camino para fijar el destinatario: el texto escrito en el
/// buscador nunca se usa como tal.
class InvitationRecipientSelected extends OrganizationInvitationEvent {
  const InvitationRecipientSelected(this.user);

  final UserSearchResult user;
}

/// El usuario descarto el destinatario elegido y vuelve al buscador.
class InvitationRecipientCleared extends OrganizationInvitationEvent {
  const InvitationRecipientCleared();
}

/// El usuario cambio el rol con el que se va a invitar.
class InvitationRoleChanged extends OrganizationInvitationEvent {
  const InvitationRoleChanged(this.role);

  final OrganizationInvitationRole role;
}

/// El usuario confirmo el envio de la invitacion.
class CreateOrganizationInvitationRequested
    extends OrganizationInvitationEvent {
  const CreateOrganizationInvitationRequested();
}

/// Se pidio el listado de invitaciones enviadas por la organizacion activa.
///
/// Lo emite `OrganizationInvitationsPage` al abrirse, al reintentar y despues
/// de un 409 al cancelar.
class LoadOrganizationInvitationsRequested extends OrganizationInvitationEvent {
  const LoadOrganizationInvitationsRequested();
}

/// El usuario confirmo la cancelacion de una invitacion pendiente.
class CancelOrganizationInvitationRequested
    extends OrganizationInvitationEvent {
  const CancelOrganizationInvitationRequested(this.invitationId);

  /// `invitationId` de la fila pulsada.
  final String invitationId;
}
