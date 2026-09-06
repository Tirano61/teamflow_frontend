import '../error/exceptions.dart';

/// Se lanza cuando se intenta resolver el `organizationId` activo sin que
/// exista una organizacion seleccionada en el contexto multiempresa.
class OrganizationNotSelectedException extends DataException {
  const OrganizationNotSelectedException([
    super.message =
        'No hay una organizacion activa seleccionada. '
        'Selecciona una organizacion para continuar.',
  ]);
}

/// Mantiene en memoria la organizacion activa del usuario.
///
/// Es solo estado runtime: no persiste nada por si mismo. Quien decide que
/// organizacion queda activa (y la persiste entre reinicios) es
/// `ActiveOrganizationResolver`, que lo repuebla despues de validar
/// `GET /me/context`.
class OrganizationContext {
  String? _organizationId;

  /// Indica si hay una organizacion activa seleccionada.
  bool get hasOrganization => _organizationId != null;

  /// Organizacion activa o `null` si todavia no se selecciono ninguna.
  String? get organizationIdOrNull => _organizationId;

  /// Organizacion activa.
  ///
  /// Lanza [OrganizationNotSelectedException] si no hay ninguna seleccionada.
  String get organizationId {
    final current = _organizationId;
    if (current == null) {
      throw const OrganizationNotSelectedException();
    }

    return current;
  }

  /// Define la organizacion activa.
  void setOrganizationId(String organizationId) {
    final normalized = organizationId.trim();
    if (normalized.isEmpty) {
      throw const ValidationException(
        'El organizationId no puede estar vacio.',
      );
    }

    _organizationId = normalized;
  }

  /// Limpia la organizacion activa (logout o cambio de organizacion).
  void clear() {
    _organizationId = null;
  }
}
