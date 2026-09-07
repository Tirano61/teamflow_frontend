import '../../../users/domain/entities/user_search_result.dart';
import '../../domain/entities/invitation_status.dart';
import '../../domain/entities/organization_invitation.dart';
import '../../domain/entities/organization_invitation_role.dart';

/// Estado de la aceptacion de una invitacion recibida.
enum OrganizationInvitationStatus { initial, accepting, success, error }

/// Estado del listado administrativo de invitaciones enviadas.
enum InvitationsListStatus { initial, loading, success, error }

/// Estado de la cancelacion de una invitacion pendiente.
///
/// `idle` es tanto el arranque como el estado despues de mostrar el resultado:
/// solo hay una cancelacion en curso a la vez.
enum CancelInvitationStatus { idle, cancelling, success, error }

/// Estado del buscador de usuarios del flujo de invitacion.
///
/// `idle` cubre tanto el arranque como la consulta demasiado corta: en ambos
/// casos no hay request en curso ni resultados que mostrar.
enum InvitationUserSearchStatus { idle, loading, success, error }

/// Estado del envio de una invitacion nueva.
enum CreateInvitationStatus { initial, sending, success, error }

/// Estado unico de la feature de invitaciones.
///
/// Cubre tres flujos independientes que nunca se usan en la misma pantalla:
/// aceptar una invitacion recibida (onboarding / seleccion de organizacion),
/// crear una invitacion desde `Miembros` y administrar las invitaciones
/// enviadas (`Invitaciones`). Cada uno tiene sus propios campos para que un
/// flujo no dispare los `listenWhen` del otro.
class OrganizationInvitationState {
  const OrganizationInvitationState({
    this.status = OrganizationInvitationStatus.initial,
    this.processingToken = '',
    this.errorMessage = '',
    this.searchQuery = '',
    this.searchStatus = InvitationUserSearchStatus.idle,
    this.searchResults = const [],
    this.searchErrorMessage = '',
    this.selectedUser,
    this.selectedRole = OrganizationInvitationRole.member,
    this.createStatus = CreateInvitationStatus.initial,
    this.createErrorMessage = '',
    this.listStatus = InvitationsListStatus.initial,
    this.invitations = const [],
    this.listErrorMessage = '',
    this.cancelStatus = CancelInvitationStatus.idle,
    this.cancellingInvitationId = '',
    this.cancelErrorMessage = '',
  });

  final OrganizationInvitationStatus status;

  /// Token de la invitacion en curso (o la ultima resuelta).
  ///
  /// Permite mostrar el loading solo en la fila pulsada.
  final String processingToken;
  final String errorMessage;

  /// Ultima consulta ya normalizada que se proceso.
  ///
  /// Sirve para descartar respuestas viejas y para el texto de `sin
  /// resultados`.
  final String searchQuery;
  final InvitationUserSearchStatus searchStatus;
  final List<UserSearchResult> searchResults;
  final String searchErrorMessage;

  /// Destinatario elegido explicitamente en la lista de resultados.
  ///
  /// Es lo unico que se envia al backend (`selectedUser.id`).
  final UserSearchResult? selectedUser;

  final OrganizationInvitationRole selectedRole;
  final CreateInvitationStatus createStatus;
  final String createErrorMessage;

  final InvitationsListStatus listStatus;

  /// Invitaciones enviadas por la organizacion activa, en el orden del backend
  /// (mas recientes primero).
  final List<OrganizationInvitation> invitations;

  final String listErrorMessage;

  final CancelInvitationStatus cancelStatus;

  /// Invitacion que se esta cancelando ahora mismo (o la ultima resuelta).
  ///
  /// Permite mostrar el loading solo en la fila pulsada.
  final String cancellingInvitationId;

  final String cancelErrorMessage;

  /// Hay una aceptacion en curso: bloquea el doble submit.
  bool get isAccepting => status == OrganizationInvitationStatus.accepting;

  /// La invitacion de [token] es la que se esta aceptando ahora mismo.
  bool isAcceptingToken(String token) =>
      isAccepting && processingToken == token.trim();

  /// Hay un envio en curso: bloquea el doble submit.
  bool get isSendingInvitation =>
      createStatus == CreateInvitationStatus.sending;

  /// Ya hay destinatario elegido: la UI pasa del buscador al detalle.
  bool get hasRecipient => selectedUser != null;

  /// El boton `Enviar invitacion` esta habilitado.
  bool get canSendInvitation => hasRecipient && !isSendingInvitation;

  /// Hay una cancelacion en curso: bloquea el doble submit y deshabilita la
  /// accion en el resto de las filas.
  bool get isCancellingInvitation =>
      cancelStatus == CancelInvitationStatus.cancelling;

  /// La invitacion [invitationId] es la que se esta cancelando ahora mismo.
  bool isCancellingInvitationId(String invitationId) =>
      isCancellingInvitation && cancellingInvitationId == invitationId.trim();

  /// Copia con la invitacion [invitationId] en el estado [status].
  ///
  /// Refleja la cancelacion sin recargar el listado: el resto de las filas y el
  /// orden del backend se mantienen.
  List<OrganizationInvitation> invitationsWithStatus(
    String invitationId,
    InvitationStatus status,
  ) {
    final normalizedId = invitationId.trim();

    return invitations
        .map(
          (invitation) => invitation.id == normalizedId
              ? invitation.copyWithStatus(status)
              : invitation,
        )
        .toList(growable: false);
  }

  OrganizationInvitationState copyWith({
    OrganizationInvitationStatus? status,
    String? processingToken,
    String? errorMessage,
    String? searchQuery,
    InvitationUserSearchStatus? searchStatus,
    List<UserSearchResult>? searchResults,
    String? searchErrorMessage,
    UserSearchResult? selectedUser,
    bool clearSelectedUser = false,
    OrganizationInvitationRole? selectedRole,
    CreateInvitationStatus? createStatus,
    String? createErrorMessage,
    InvitationsListStatus? listStatus,
    List<OrganizationInvitation>? invitations,
    String? listErrorMessage,
    CancelInvitationStatus? cancelStatus,
    String? cancellingInvitationId,
    String? cancelErrorMessage,
  }) {
    return OrganizationInvitationState(
      status: status ?? this.status,
      processingToken: processingToken ?? this.processingToken,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      searchStatus: searchStatus ?? this.searchStatus,
      searchResults: searchResults ?? this.searchResults,
      searchErrorMessage: searchErrorMessage ?? this.searchErrorMessage,
      selectedUser: clearSelectedUser
          ? null
          : selectedUser ?? this.selectedUser,
      selectedRole: selectedRole ?? this.selectedRole,
      createStatus: createStatus ?? this.createStatus,
      createErrorMessage: createErrorMessage ?? this.createErrorMessage,
      listStatus: listStatus ?? this.listStatus,
      invitations: invitations ?? this.invitations,
      listErrorMessage: listErrorMessage ?? this.listErrorMessage,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      cancellingInvitationId:
          cancellingInvitationId ?? this.cancellingInvitationId,
      cancelErrorMessage: cancelErrorMessage ?? this.cancelErrorMessage,
    );
  }
}
