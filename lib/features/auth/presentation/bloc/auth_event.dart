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

/// Recarga de `GET /me/context` y de la organizacion activa derivada de el.
///
/// Es la accion reutilizable que dispara cualquier cambio de pertenencia
/// (crear organizacion, aceptar invitacion): la regla de 0 / 1 / varias
/// organizaciones se resuelve una sola vez dentro de `AuthBloc`.
class AuthUserContextRefreshRequested extends AuthEvent {
  const AuthUserContextRefreshRequested();
}

/// Reintento manual de `GET /me/context` tras un fallo de carga.
///
/// Es un [AuthUserContextRefreshRequested] con otro nombre de intencion: lo
/// atiende el mismo handler para no duplicar la logica de resolucion.
class AuthUserContextRetryRequested extends AuthUserContextRefreshRequested {
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
