import '../../../domain/entities/discussion.dart';

/// Seleccion de filtros avanzados aplicada al tablero de discussions.
class DiscussionAdvancedFilterSelection {
  const DiscussionAdvancedFilterSelection({
    required this.type,
    required this.moduleIds,
    required this.componentIds,
    required this.tagIds,
  });

  static const DiscussionAdvancedFilterSelection empty =
      DiscussionAdvancedFilterSelection(
        type: null,
        moduleIds: <String>{},
        componentIds: <String>{},
        tagIds: <String>{},
      );

  final DiscussionType? type;
  final Set<String> moduleIds;
  final Set<String> componentIds;
  final Set<String> tagIds;

  bool get hasSelection =>
      type != null ||
      moduleIds.isNotEmpty ||
      componentIds.isNotEmpty ||
      tagIds.isNotEmpty;
}
