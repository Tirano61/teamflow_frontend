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

/// El usuario eligio una organizacion en `OrganizationSelectionPage`.
class AuthOrganizationSelected extends AuthEvent {
  const AuthOrganizationSelected(this.organizationId);

  final String organizationId;
}

/// Reintento manual de `GET /me/context` tras un fallo de carga.
class AuthUserContextRetryRequested extends AuthEvent {
  const AuthUserContextRetryRequested();
}

class AuthSessionRequiredDetected extends AuthEvent {
  const AuthSessionRequiredDetected(this.message);

  final String message;
}

class AuthSessionExpiredDetected extends AuthEvent {
  const AuthSessionExpiredDetected(this.message);

  final String message;
}
