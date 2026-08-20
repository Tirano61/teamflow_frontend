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
    this.errorMessage = '',
    this.infoMessage = '',
  });

  final AuthStatus status;
  final AuthSession? session;
  final String errorMessage;
  final String infoMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    bool clearSession = false,
    String? errorMessage,
    String? infoMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : session ?? this.session,
      errorMessage: errorMessage ?? this.errorMessage,
      infoMessage: infoMessage ?? this.infoMessage,
    );
  }
}
