import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_changes.dart';

/// Body de `PATCH /organizations/{organizationId}/workspace/discussions/{id}`.
///
/// Solo serializa los campos presentes: un campo omitido no se modifica y una
/// lista vacia elimina todas las asociaciones de ese tipo. `initialMessageContent`
/// e `id` nunca viajan en el PATCH.
class DiscussionChangesModel {
  const DiscussionChangesModel({
    this.title,
    this.type,
    this.moduleIds,
    this.componentIds,
    this.tagIds,
  });

  factory DiscussionChangesModel.fromEntity(DiscussionChanges changes) {
    return DiscussionChangesModel(
      title: changes.title,
      type: changes.type,
      moduleIds: changes.moduleIds,
      componentIds: changes.componentIds,
      tagIds: changes.tagIds,
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

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{};

    final normalizedTitle = title?.trim();
    if (normalizedTitle != null) {
      payload['title'] = normalizedTitle;
    }

    final selectedType = type;
    if (selectedType != null) {
      payload['type'] = selectedType.apiValue;
    }

    final selectedModuleIds = moduleIds;
    if (selectedModuleIds != null) {
      payload['moduleIds'] = _normalizeIds(selectedModuleIds);
    }

    final selectedComponentIds = componentIds;
    if (selectedComponentIds != null) {
      payload['componentIds'] = _normalizeIds(selectedComponentIds);
    }

    final selectedTagIds = tagIds;
    if (selectedTagIds != null) {
      payload['tagIds'] = _normalizeIds(selectedTagIds);
    }

    return payload;
  }

  List<String> _normalizeIds(List<String> ids) {
    return ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}
