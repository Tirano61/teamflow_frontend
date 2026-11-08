import 'discussion.dart';

/// Cambios de `PATCH /organizations/{organizationId}/workspace/discussions/{id}`.
///
/// Todos los campos del PATCH son opcionales en el backend:
/// - `null`: el campo se omite y no se modifica.
/// - lista vacia en `moduleIds`/`componentIds`/`tagIds`: elimina todas las
///   asociaciones de ese tipo.
///
/// Reemplazar contexto (`moduleIds`/`componentIds`/`tagIds`) requiere
/// `OWNER`/`ADMIN`/`DEVELOPER`; el backend responde 403 a un `MEMBER` que los
/// incluya aunque no cambien, por eso solo viajan cuando cambiaron.
class DiscussionChanges {
  const DiscussionChanges({
    this.title,
    this.type,
    this.moduleIds,
    this.componentIds,
    this.tagIds,
  });

  /// Solo los campos que difieren de [original]. El contexto solo se compara
  /// (y se envia) con [includeContext], que el llamador decide segun
  /// `DiscussionPermissions.canManageContext`.
  factory DiscussionChanges.between(
    Discussion original, {
    required String title,
    required DiscussionType type,
    required Iterable<String> moduleIds,
    required Iterable<String> componentIds,
    required Iterable<String> tagIds,
    required bool includeContext,
  }) {
    final normalizedTitle = title.trim();

    return DiscussionChanges(
      title: normalizedTitle == original.title.trim() ? null : normalizedTitle,
      type: type == original.type ? null : type,
      moduleIds: includeContext
          ? changedIds(original.resolvedModuleIds, moduleIds)
          : null,
      componentIds: includeContext
          ? changedIds(original.resolvedComponentIds, componentIds)
          : null,
      tagIds: includeContext
          ? changedIds(original.resolvedTagIds, tagIds)
          : null,
    );
  }

  final String? title;
  final DiscussionType? type;
  final List<String>? moduleIds;
  final List<String>? componentIds;
  final List<String>? tagIds;

  bool get isEmpty =>
      title == null &&
      type == null &&
      moduleIds == null &&
      componentIds == null &&
      tagIds == null;

  /// `null` si [next] tiene los mismos ids que [current] (sin importar orden
  /// ni duplicados); si no, [next] normalizado y ordenado.
  static List<String>? changedIds(
    Iterable<String> current,
    Iterable<String> next,
  ) {
    final currentSet = _normalize(current);
    final nextSet = _normalize(next);

    if (currentSet.length == nextSet.length &&
        currentSet.containsAll(nextSet)) {
      return null;
    }

    return List<String>.unmodifiable(nextSet.toList()..sort());
  }

  static Set<String> _normalize(Iterable<String> ids) {
    return ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
  }
}
