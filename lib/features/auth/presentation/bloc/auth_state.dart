import '../../../user_context/domain/entities/user_context.dart';
import '../../../user_context/domain/entities/user_organization.dart';
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
    this.activeOrganizationId = '',
    this.errorMessage = '',
    this.infoMessage = '',
    this.userContextErrorMessage = '',
    this.isUserContextLoading = false,
  });

  final AuthStatus status;
  final AuthSession? session;

  /// Contexto del usuario autenticado (`GET /me/context`).
  ///
  /// Queda disponible para el siguiente paso (seleccion de organizacion,
  /// invitaciones pendientes). Es `null` si aun no se cargo o si fallo.
  final UserContext? userContext;

  /// Organizacion activa aplicada a `OrganizationContext`.
  ///
  /// Se completa cuando el usuario tiene exactamente una organizacion
  /// (autoseleccion) o cuando elige una en la pantalla de seleccion. Vacio
  /// mientras no haya organizacion activa.
  final String activeOrganizationId;
  final String errorMessage;
  final String infoMessage;

  /// Motivo por el que no se pudo cargar `/me/context`. Vacio si no hubo error.
  final String userContextErrorMessage;

  /// `true` mientras se esta recargando `/me/context` (reintento manual).
  final bool isUserContextLoading;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;

  /// El usuario no pertenece a ninguna organizacion todavia.
  bool get hasNoOrganizations => userContext?.hasOrganizations == false;

  /// El usuario pertenece a varias organizaciones y debe elegir una.
  bool get requiresOrganizationSelection =>
      userContext?.requiresOrganizationSelection ?? false;

  /// Organizaciones del usuario segun el ultimo `/me/context`.
  ///
  /// Vacio mientras no haya contexto cargado.
  List<UserOrganization> get organizations =>
      userContext?.organizations ?? const <UserOrganization>[];

  /// Organizacion activa resuelta contra [organizations].
  ///
  /// Se resuelve en memoria sobre el contexto ya cargado: conocer el nombre de
  /// la organizacion activa no requiere ninguna llamada extra. Es `null` si no
  /// hay organizacion activa o si el id todavia no aparece en el contexto.
  UserOrganization? get activeOrganization {
    if (activeOrganizationId.isEmpty) {
      return null;
    }

    for (final organization in organizations) {
      if (organization.id == activeOrganizationId) {
        return organization;
      }
    }

    return null;
  }

  /// El usuario puede cambiar de organizacion sin cerrar sesion.
  ///
  /// Coincide numericamente con [requiresOrganizationSelection], pero expresa
  /// otra intencion: aca ya hay una organizacion activa y el cambio es
  /// opcional.
  bool get canSwitchOrganization => organizations.length > 1;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    bool clearSession = false,
    UserContext? userContext,
    bool clearUserContext = false,
    String? activeOrganizationId,
    String? errorMessage,
    String? infoMessage,
    String? userContextErrorMessage,
    bool? isUserContextLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : session ?? this.session,
      userContext: clearUserContext ? null : userContext ?? this.userContext,
      activeOrganizationId: activeOrganizationId ?? this.activeOrganizationId,
      errorMessage: errorMessage ?? this.errorMessage,
      infoMessage: infoMessage ?? this.infoMessage,
      userContextErrorMessage:
          userContextErrorMessage ?? this.userContextErrorMessage,
      isUserContextLoading: isUserContextLoading ?? this.isUserContextLoading,
    );
  }
}
