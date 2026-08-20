sealed class AuthEvent {
  const AuthEvent();
}

class AuthBootstrapRequested extends AuthEvent {
  const AuthBootstrapRequested();
}

class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthSessionRequiredDetected extends AuthEvent {
  const AuthSessionRequiredDetected(this.message);

  final String message;
}

class AuthSessionExpiredDetected extends AuthEvent {
  const AuthSessionExpiredDetected(this.message);

  final String message;
}
