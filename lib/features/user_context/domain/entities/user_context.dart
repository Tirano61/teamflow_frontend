import 'context_user.dart';
import 'pending_invitation.dart';
import 'user_organization.dart';

/// Contexto completo del usuario autenticado (`GET /me/context`).
///
/// Concentra la regla de resolucion de organizacion activa para que la capa de
/// presentacion no tenga que decidirla.
class UserContext {
  const UserContext({
    required this.user,
    required this.organizations,
    required this.pendingInvitations,
    required this.organizationCount,
  });

  final ContextUser user;
  final List<UserOrganization> organizations;
  final List<PendingInvitation> pendingInvitations;
  final int organizationCount;

  bool get hasOrganizations => organizations.isNotEmpty;

  /// El usuario pertenece a exactamente una organizacion.
  bool get hasSingleOrganization => organizations.length == 1;

  /// El usuario pertenece a varias organizaciones: debe elegir una.
  bool get requiresOrganizationSelection => organizations.length > 1;

  bool get hasPendingInvitations => pendingInvitations.isNotEmpty;

  /// Unica organizacion del usuario, o `null` si tiene 0 o mas de 1.
  UserOrganization? get singleOrganization =>
      hasSingleOrganization ? organizations.first : null;

  /// Organizacion que puede seleccionarse automaticamente.
  ///
  /// Solo devuelve un id cuando hay exactamente una organizacion. Con 0 o con
  /// varias devuelve `null`: no se debe inventar ni elegir por el usuario.
  String? get autoSelectableOrganizationId {
    final organization = singleOrganization;
    if (organization == null) {
      return null;
    }

    final id = organization.id.trim();
    return id.isEmpty ? null : id;
  }
}
