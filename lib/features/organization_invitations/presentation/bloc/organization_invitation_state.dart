enum OrganizationInvitationStatus { initial, accepting, success, error }

class OrganizationInvitationState {
  const OrganizationInvitationState({
    this.status = OrganizationInvitationStatus.initial,
    this.processingToken = '',
    this.errorMessage = '',
  });

  final OrganizationInvitationStatus status;

  /// Token de la invitacion en curso (o la ultima resuelta).
  ///
  /// Permite mostrar el loading solo en la fila pulsada.
  final String processingToken;
  final String errorMessage;

  /// Hay una aceptacion en curso: bloquea el doble submit.
  bool get isAccepting => status == OrganizationInvitationStatus.accepting;

  /// La invitacion de [token] es la que se esta aceptando ahora mismo.
  bool isAcceptingToken(String token) =>
      isAccepting && processingToken == token.trim();

  OrganizationInvitationState copyWith({
    OrganizationInvitationStatus? status,
    String? processingToken,
    String? errorMessage,
  }) {
    return OrganizationInvitationState(
      status: status ?? this.status,
      processingToken: processingToken ?? this.processingToken,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
