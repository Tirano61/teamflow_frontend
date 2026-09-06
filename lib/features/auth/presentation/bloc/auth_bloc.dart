import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/network/auth_token_provider.dart';
import '../../../../core/organization/organization_context.dart';
import '../../../user_context/domain/entities/user_context.dart';
import '../../../user_context/domain/usecases/load_user_context.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUseCase loginUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
    required LogoutUseCase logoutUseCase,
    required AuthTokenProvider authTokenProvider,
    required LoadUserContext loadUserContext,
    required OrganizationContext organizationContext,
  }) : _loginUseCase = loginUseCase,
       _restoreSessionUseCase = restoreSessionUseCase,
       _logoutUseCase = logoutUseCase,
       _authTokenProvider = authTokenProvider,
       _loadUserContext = loadUserContext,
       _organizationContext = organizationContext,
       super(const AuthState()) {
    on<AuthBootstrapRequested>(_onBootstrapRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthOrganizationSelected>(_onOrganizationSelected);
    // Cubre tambien `AuthUserContextRetryRequested`, que es un subtipo: se
    // registra solo el evento base para no ejecutar el handler dos veces.
    on<AuthUserContextRefreshRequested>(_onUserContextRefreshRequested);
    on<AuthSessionRequiredDetected>(_onSessionRequiredDetected);
    on<AuthSessionExpiredDetected>(_onSessionExpiredDetected);

    _sessionSignalsSubscription = _authTokenProvider.sessionSignals.listen((
      signal,
    ) {
      if (signal.type == AuthSessionSignalType.sessionRequired) {
        add(AuthSessionRequiredDetected(signal.message));
        return;
      }

      add(AuthSessionExpiredDetected(signal.message));
    });

    add(const AuthBootstrapRequested());
  }

  final LoginUseCase _loginUseCase;
  final RestoreSessionUseCase _restoreSessionUseCase;
  final LogoutUseCase _logoutUseCase;
  final AuthTokenProvider _authTokenProvider;
  final LoadUserContext _loadUserContext;
  final OrganizationContext _organizationContext;
  StreamSubscription<AuthSessionSignal>? _sessionSignalsSubscription;

  Future<void> _onBootstrapRequested(
    AuthBootstrapRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.checking,
        errorMessage: '',
        infoMessage: '',
      ),
    );

    final result = await _restoreSessionUseCase();

    if (result is Success<AuthSession?>) {
      final session = result.data;
      if (session != null && session.hasValidToken) {
        final resolution = await _resolveUserContext();
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            session: session,
            userContext: resolution.userContext,
            clearUserContext: resolution.userContext == null,
            activeOrganizationId: resolution.activeOrganizationId,
            errorMessage: '',
            infoMessage: '',
            userContextErrorMessage: resolution.errorMessage,
            isUserContextLoading: false,
          ),
        );
        return;
      }

      emit(_unauthenticatedState());
      return;
    }

    if (result is FailureResult<AuthSession?>) {
      emit(_unauthenticatedState(errorMessage: result.failure.message));
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final email = event.email.trim();
    final password = event.password;

    if (email.isEmpty || password.trim().isEmpty) {
      emit(
        _unauthenticatedState(
          errorMessage: 'Email y password son obligatorios.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        errorMessage: '',
        infoMessage: '',
      ),
    );

    final result = await _loginUseCase(email: email, password: password);

    if (result is Success<AuthSession>) {
      // El contexto se resuelve antes de emitir `authenticated`: la navegacion
      // al workspace ocurre recien cuando ya se analizo `/me/context`.
      final resolution = await _resolveUserContext();
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          session: result.data,
          userContext: resolution.userContext,
          clearUserContext: resolution.userContext == null,
          activeOrganizationId: resolution.activeOrganizationId,
          errorMessage: '',
          infoMessage: '',
          userContextErrorMessage: resolution.errorMessage,
          isUserContextLoading: false,
        ),
      );
      return;
    }

    if (result is FailureResult<AuthSession>) {
      emit(_unauthenticatedState(errorMessage: result.failure.message));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(_unauthenticatedState());
  }

  /// Aplica la organizacion elegida por el usuario al contexto multiempresa.
  ///
  /// Es el unico punto que cambia la organizacion activa, tanto en la seleccion
  /// posterior al login como en el cambio desde el Workspace: actualiza
  /// `OrganizationContext` (lo que consume el Workspace) y `activeOrganizationId`
  /// en el estado. La seleccion no se persiste todavia: solo vive en memoria.
  Future<void> _onOrganizationSelected(
    AuthOrganizationSelected event,
    Emitter<AuthState> emit,
  ) async {
    final organizationId = event.organizationId.trim();
    if (!state.isAuthenticated || organizationId.isEmpty) {
      return;
    }

    // Reelegir la organizacion ya activa no es un cambio: no se emite estado
    // para no reiniciar el Workspace sin motivo.
    if (state.activeOrganizationId == organizationId) {
      return;
    }

    // Solo se acepta una organizacion a la que el usuario pertenece segun el
    // ultimo `/me/context`.
    final belongsToUser = state.organizations.any(
      (organization) => organization.id == organizationId,
    );
    if (!belongsToUser) {
      return;
    }

    _organizationContext.setOrganizationId(organizationId);
    emit(state.copyWith(activeOrganizationId: organizationId));
  }

  /// Recarga `GET /me/context` y vuelve a aplicar la regla de organizacion
  /// activa.
  ///
  /// Es el unico punto de recarga del contexto: lo usan el reintento manual
  /// tras un fallo y las acciones que cambian la pertenencia del usuario
  /// (crear organizacion, aceptar invitacion). La guarda de
  /// `isUserContextLoading` evita recargas superpuestas.
  Future<void> _onUserContextRefreshRequested(
    AuthUserContextRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!state.isAuthenticated || state.isUserContextLoading) {
      return;
    }

    emit(
      state.copyWith(isUserContextLoading: true, userContextErrorMessage: ''),
    );

    final resolution = await _resolveUserContext();

    // La sesion pudo caer mientras se recargaba el contexto (401): en ese caso
    // manda el flujo de sesion existente y no se pisa el estado.
    if (!state.isAuthenticated) {
      return;
    }

    emit(
      state.copyWith(
        userContext: resolution.userContext,
        clearUserContext: resolution.userContext == null,
        activeOrganizationId: resolution.activeOrganizationId,
        userContextErrorMessage: resolution.errorMessage,
        isUserContextLoading: false,
      ),
    );
  }

  Future<void> _onSessionRequiredDetected(
    AuthSessionRequiredDetected event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(_unauthenticatedState(infoMessage: event.message));
  }

  Future<void> _onSessionExpiredDetected(
    AuthSessionExpiredDetected event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(_unauthenticatedState(infoMessage: event.message));
  }

  /// Estado sin sesion: limpia tambien el contexto multiempresa en memoria.
  AuthState _unauthenticatedState({
    String errorMessage = '',
    String infoMessage = '',
  }) {
    _organizationContext.clear();

    return state.copyWith(
      status: AuthStatus.unauthenticated,
      clearSession: true,
      clearUserContext: true,
      activeOrganizationId: '',
      errorMessage: errorMessage,
      infoMessage: infoMessage,
      userContextErrorMessage: '',
      isUserContextLoading: false,
    );
  }

  /// Carga `/me/context` y aplica la regla de organizacion activa:
  /// - exactamente 1 organizacion: se selecciona automaticamente;
  /// - 0 o varias: `OrganizationContext` queda vacio (lo resuelve la UI).
  Future<_UserContextResolution> _resolveUserContext() async {
    _organizationContext.clear();

    final result = await _loadUserContext();

    if (result is Success<UserContext>) {
      final userContext = result.data;
      final organizationId = userContext.autoSelectableOrganizationId;

      if (organizationId != null) {
        _organizationContext.setOrganizationId(organizationId);
      }

      return _UserContextResolution(
        userContext: userContext,
        activeOrganizationId: organizationId ?? '',
      );
    }

    if (result is FailureResult<UserContext>) {
      return _UserContextResolution(errorMessage: result.failure.message);
    }

    return const _UserContextResolution();
  }

  @override
  Future<void> close() async {
    await _sessionSignalsSubscription?.cancel();
    return super.close();
  }
}

/// Resultado interno de resolver `/me/context` tras autenticar.
class _UserContextResolution {
  const _UserContextResolution({
    this.userContext,
    this.activeOrganizationId = '',
    this.errorMessage = '',
  });

  final UserContext? userContext;

  /// Organizacion aplicada a `OrganizationContext`, o vacio si quedo sin
  /// resolver (0 organizaciones, varias organizaciones o error de carga).
  final String activeOrganizationId;
  final String errorMessage;
}
