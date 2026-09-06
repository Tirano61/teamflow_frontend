import '../../features/user_context/domain/entities/user_context.dart';
import 'active_organization_storage.dart';
import 'organization_context.dart';

/// Decide que organizacion queda activa y mantiene sincronizadas las dos capas
/// que la representan: el runtime ([OrganizationContext]) y la persistencia
/// ([ActiveOrganizationStorage]).
///
/// Existe para que la regla de organizacion activa viva en un solo lugar y para
/// que `AuthBloc` no tenga que tocar el storage en cada handler. Devuelve
/// siempre el id aplicado (o vacio) para que el bloc lo copie a
/// `AuthState.activeOrganizationId` sin volver a decidir nada.
class ActiveOrganizationResolver {
  const ActiveOrganizationResolver({
    required OrganizationContext organizationContext,
    required ActiveOrganizationStorage storage,
  }) : _organizationContext = organizationContext,
       _storage = storage;

  final OrganizationContext _organizationContext;
  final ActiveOrganizationStorage _storage;

  /// Resuelve la organizacion activa contra un `/me/context` recien cargado.
  ///
  /// Solo debe llamarse cuando la carga del contexto fue exitosa: un id
  /// persistido nunca se reutiliza sin la lista de organizaciones vigente.
  ///
  /// ```text
  /// 0 organizaciones   -> sin organizacion activa, se borra la persistida
  /// 1 organizacion     -> autoseleccion, se persiste
  /// >1 organizaciones  -> se restaura la persistida solo si sigue en el
  ///                       contexto; si no, se borra y decide el usuario
  /// ```
  Future<String> resolveForUserContext(UserContext userContext) async {
    _organizationContext.clear();

    if (!userContext.hasOrganizations) {
      await _storage.clear();
      return '';
    }

    final autoSelectableId = userContext.autoSelectableOrganizationId;
    if (autoSelectableId != null) {
      return _apply(autoSelectableId);
    }

    final storedId = await _storage.read();

    // Seguridad tenant: el id guardado se acepta solo si aparece en el contexto
    // recien validado. Si el usuario dejo de pertenecer a esa organizacion, la
    // seleccion se invalida y vuelve a decidir el usuario.
    if (storedId == null || !_belongsToUserContext(storedId, userContext)) {
      await _storage.clear();
      return '';
    }

    return _apply(storedId);
  }

  /// Aplica una seleccion explicita ya validada por el llamador.
  Future<String> select(String organizationId) => _apply(organizationId);

  /// Limpia solo la organizacion activa en memoria, sin tocar la persistida.
  ///
  /// Se usa mientras se recarga `/me/context`: durante la recarga no debe
  /// quedar ningun tenant activo, pero si la carga falla la preferencia
  /// guardada debe sobrevivir para el proximo intento valido.
  void clearRuntime() {
    _organizationContext.clear();
  }

  /// Borra la organizacion activa en memoria y en disco.
  ///
  /// Se usa al cerrar sesion para que la eleccion de un usuario no llegue a la
  /// sesion del siguiente.
  Future<void> clear() async {
    _organizationContext.clear();
    await _storage.clear();
  }

  Future<String> _apply(String organizationId) async {
    _organizationContext.setOrganizationId(organizationId);
    await _storage.save(organizationId);

    return organizationId;
  }

  bool _belongsToUserContext(String organizationId, UserContext userContext) {
    return userContext.organizations.any(
      (organization) => organization.id == organizationId,
    );
  }
}
