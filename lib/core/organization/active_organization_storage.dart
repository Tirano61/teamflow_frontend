import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia del `organizationId` activo entre reinicios de la app.
///
/// Guarda unicamente el id: el nombre, el slug, el rol y la lista completa de
/// organizaciones siempre se releen desde `GET /me/context`. Un id guardado es
/// solo una preferencia, nunca una autorizacion: quien lo lee debe validarlo
/// contra el contexto recien cargado antes de usarlo.
abstract class ActiveOrganizationStorage {
  /// Id persistido, o `null` si no hay ninguno guardado.
  Future<String?> read();

  /// Guarda [organizationId] como organizacion activa.
  Future<void> save(String organizationId);

  /// Borra el id persistido (logout o seleccion invalidada).
  Future<void> clear();
}

/// Implementacion sobre `SharedPreferences`, el mismo mecanismo de
/// almacenamiento local que ya usa la sesion de auth.
class SharedPreferencesActiveOrganizationStorage
    implements ActiveOrganizationStorage {
  const SharedPreferencesActiveOrganizationStorage({
    required SharedPreferences sharedPreferences,
  }) : _sharedPreferences = sharedPreferences;

  static const String _storageKey = 'active_organization_id';

  final SharedPreferences _sharedPreferences;

  @override
  Future<String?> read() async {
    final raw = _sharedPreferences.getString(_storageKey)?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return raw;
  }

  @override
  Future<void> save(String organizationId) async {
    final normalized = organizationId.trim();
    if (normalized.isEmpty) {
      // Un id vacio no es una seleccion valida: se borra en lugar de guardarlo.
      await clear();
      return;
    }

    await _sharedPreferences.setString(_storageKey, normalized);
  }

  @override
  Future<void> clear() async {
    await _sharedPreferences.remove(_storageKey);
  }
}
