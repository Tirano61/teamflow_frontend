import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/network/auth_token_provider.dart';
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
  }) : _loginUseCase = loginUseCase,
       _restoreSessionUseCase = restoreSessionUseCase,
       _logoutUseCase = logoutUseCase,
       _authTokenProvider = authTokenProvider,
       super(const AuthState()) {
    on<AuthBootstrapRequested>(_onBootstrapRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
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
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            session: session,
            errorMessage: '',
            infoMessage: '',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearSession: true,
          errorMessage: '',
          infoMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<AuthSession?>) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearSession: true,
          errorMessage: result.failure.message,
          infoMessage: '',
        ),
      );
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
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearSession: true,
          errorMessage: 'Email y password son obligatorios.',
          infoMessage: '',
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
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          session: result.data,
          errorMessage: '',
          infoMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<AuthSession>) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearSession: true,
          errorMessage: result.failure.message,
          infoMessage: '',
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearSession: true,
        errorMessage: '',
        infoMessage: '',
      ),
    );
  }

  Future<void> _onSessionRequiredDetected(
    AuthSessionRequiredDetected event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearSession: true,
        errorMessage: '',
        infoMessage: event.message,
      ),
    );
  }

  Future<void> _onSessionExpiredDetected(
    AuthSessionExpiredDetected event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearSession: true,
        errorMessage: '',
        infoMessage: event.message,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sessionSignalsSubscription?.cancel();
    return super.close();
  }
}
