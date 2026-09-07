import '../../../users/domain/entities/user_search_result.dart';
import '../../domain/entities/organization_invitation_role.dart';

/// Estado de la aceptacion de una invitacion recibida.
enum OrganizationInvitationStatus { initial, accepting, success, error }

/// Estado del buscador de usuarios del flujo de invitacion.
///
/// `idle` cubre tanto el arranque como la consulta demasiado corta: en ambos
/// casos no hay request en curso ni resultados que mostrar.
enum InvitationUserSearchStatus { idle, loading, success, error }

/// Estado del envio de una invitacion nueva.
enum CreateInvitationStatus { initial, sending, success, error }

/// Estado unico de la feature de invitaciones.
///
/// Cubre dos flujos independientes que nunca se usan en la misma pantalla:
/// aceptar una invitacion recibida (onboarding / seleccion de organizacion) y
/// crear una invitacion desde `Miembros`. Cada uno tiene sus propios campos
/// para que un flujo no dispare los `listenWhen` del otro.
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
    );
  }
}
