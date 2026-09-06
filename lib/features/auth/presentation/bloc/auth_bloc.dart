import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/network/auth_token_provider.dart';
import '../../../../core/organization/active_organization_resolver.dart';
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
    required ActiveOrganizationResolver activeOrganizationResolver,
  }) : _loginUseCase = loginUseCase,
       _restoreSessionUseCase = restoreSessionUseCase,
       _logoutUseCase = logoutUseCase,
       _authTokenProvider = authTokenProvider,
       _loadUserContext = loadUserContext,
       _activeOrganizationResolver = activeOrganizationResolver,
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
  final ActiveOrganizationResolver _activeOrganizationResolver;
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

      emit(await _unauthenticatedState());
      return;
    }

    if (result is FailureResult<AuthSession?>) {
      emit(await _unauthenticatedState(errorMessage: result.failure.message));
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
        await _unauthenticatedState(
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
      emit(await _unauthenticatedState(errorMessage: result.failure.message));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(await _unauthenticatedState());
  }

  /// Aplica la organizacion elegida por el usuario al contexto multiempresa.
  ///
  /// Es el unico punto que cambia la organizacion activa, tanto en la seleccion
  /// posterior al login como en el cambio desde el Workspace: actualiza
  /// `OrganizationContext` (lo que consume el Workspace), persiste el id y
  /// refleja `activeOrganizationId` en el estado.
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

    await _activeOrganizationResolver.select(organizationId);
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
    emit(await _unauthenticatedState(infoMessage: event.message));
  }

  Future<void> _onSessionExpiredDetected(
    AuthSessionExpiredDetected event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(await _unauthenticatedState(infoMessage: event.message));
  }

  /// Estado sin sesion: limpia el contexto multiempresa en memoria y borra la
  /// organizacion persistida.
  ///
  /// El borrado cubre todas las salidas de sesion (logout explicito, sesion
  /// expirada o ausente) para que la eleccion de un usuario nunca alcance la
  /// sesion del siguiente.
  Future<AuthState> _unauthenticatedState({
    String errorMessage = '',
    String infoMessage = '',
  }) async {
    await _activeOrganizationResolver.clear();

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

  /// Carga `/me/context` y delega la regla de organizacion activa en
  /// [ActiveOrganizationResolver]:
  /// - exactamente 1 organizacion: se selecciona automaticamente y se persiste;
  /// - varias: se restaura la persistida si sigue en el contexto, o queda vacio
  ///   para que elija el usuario;
  /// - 0: queda vacio y se borra cualquier organizacion persistida.
  ///
  /// Es el unico punto de resolucion: lo comparten el bootstrap, el login y el
  /// refresh, asi que la regla no se duplica ni se puede desincronizar.
  Future<_UserContextResolution> _resolveUserContext() async {
    // Mientras se recarga el contexto no debe quedar ningun tenant activo. Solo
    // se limpia memoria: la preferencia persistida se decide con el resultado.
    _activeOrganizationResolver.clearRuntime();

    final result = await _loadUserContext();

    if (result is Success<UserContext>) {
      final userContext = result.data;
      final organizationId = await _activeOrganizationResolver
          .resolveForUserContext(userContext);

      return _UserContextResolution(
        userContext: userContext,
        activeOrganizationId: organizationId,
      );
    }

    if (result is FailureResult<UserContext>) {
      // El contexto no se pudo validar: no se restaura ni se borra la
      // organizacion persistida, queda intacta para el proximo intento valido.
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
