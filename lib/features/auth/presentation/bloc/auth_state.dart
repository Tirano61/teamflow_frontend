import '../../../user_context/domain/entities/user_context.dart';
import '../../domain/entities/auth_session.dart';

enum AuthStatus {
  initial,
  checking,
  unauthenticated,
  authenticating,
  authenticated,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.session,
    this.userContext,
    this.errorMessage = '',
    this.infoMessage = '',
    this.userContextErrorMessage = '',
  });

  final AuthStatus status;
  final AuthSession? session;

  /// Contexto del usuario autenticado (`GET /me/context`).
  ///
  /// Queda disponible para el siguiente paso (seleccion de organizacion,
  /// invitaciones pendientes). Es `null` si aun no se cargo o si fallo.
  final UserContext? userContext;
  final String errorMessage;
  final String infoMessage;

  /// Motivo por el que no se pudo cargar `/me/context`. Vacio si no hubo error.
  final String userContextErrorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;

  /// El usuario no pertenece a ninguna organizacion todavia.
  bool get hasNoOrganizations => userContext?.hasOrganizations == false;

  /// El usuario pertenece a varias organizaciones y debe elegir una.
  bool get requiresOrganizationSelection =>
      userContext?.requiresOrganizationSelection ?? false;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    bool clearSession = false,
    UserContext? userContext,
    bool clearUserContext = false,
    String? errorMessage,
    String? infoMessage,
    String? userContextErrorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : session ?? this.session,
      userContext: clearUserContext ? null : userContext ?? this.userContext,
      errorMessage: errorMessage ?? this.errorMessage,
      infoMessage: infoMessage ?? this.infoMessage,
      userContextErrorMessage:
          userContextErrorMessage ?? this.userContextErrorMessage,
    );
  }
}
