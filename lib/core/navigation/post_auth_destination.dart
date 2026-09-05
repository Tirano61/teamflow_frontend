import '../../features/auth/presentation/bloc/auth_state.dart';

/// Pantalla que corresponde al usuario segun su estado de autenticacion y su
/// contexto (`GET /me/context`).
enum PostAuthDestination {
  /// Auth todavia resolviendo: bootstrap, login o restauracion de sesion.
  pending,

  /// Sin sesion valida.
  login,

  /// Flujo principal de TeamFlow (requiere organizacion activa).
  workspace,

  /// El usuario pertenece a varias organizaciones y debe elegir una.
  organizationSelection,

  /// El usuario todavia no pertenece a ninguna organizacion.
  noOrganization,

  /// `GET /me/context` fallo: no se puede decidir el destino real.
  userContextError,
}

/// Unica fuente de verdad de la decision de navegacion posterior al login.
///
/// La regla vive aca (y no repartida por widgets) para que la UI solo tenga que
/// renderizar el destino ya resuelto:
///
/// ```text
/// authenticated
///     |
///     +-- 1 organizacion ----> workspace (auto seleccionada por AuthBloc)
///     |
///     +-- >1 organizaciones -> organizationSelection
///     |
///     +-- 0 organizaciones ---> noOrganization
/// ```
class PostAuthDestinationResolver {
  const PostAuthDestinationResolver._();

  static PostAuthDestination resolve(AuthState state) {
    switch (state.status) {
      case AuthStatus.initial:
      case AuthStatus.checking:
      case AuthStatus.authenticating:
        return PostAuthDestination.pending;
      case AuthStatus.unauthenticated:
        return PostAuthDestination.login;
      case AuthStatus.authenticated:
        break;
    }

    if (!state.isAuthenticated) {
      return PostAuthDestination.login;
    }

    final userContext = state.userContext;
    if (userContext == null) {
      // Sin contexto no se puede entrar al Workspace: se muestra el error de
      // carga con opcion de reintentar, nunca el flujo principal.
      return PostAuthDestination.userContextError;
    }

    // Cubre tanto la organizacion autoseleccionada (1 sola) como la elegida
    // manualmente en `OrganizationSelectionPage`.
    if (state.activeOrganizationId.isNotEmpty) {
      return PostAuthDestination.workspace;
    }

    if (!userContext.hasOrganizations) {
      return PostAuthDestination.noOrganization;
    }

    return PostAuthDestination.organizationSelection;
  }
}
