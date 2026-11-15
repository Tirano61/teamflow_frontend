import 'discussion.dart';
import 'discussion_summary.dart';

/// Una pagina de `GET .../discussions` (paginacion por cursor).
class DiscussionPage {
  const DiscussionPage({
    required this.items,
    required this.nextCursor,
    required this.hasNextPage,
    required this.summary,
  });

  final List<Discussion> items;

  /// `pageInfo.nextCursor`: opaco, se reenvia sin interpretarlo. `null` cuando
  /// no hay pagina siguiente.
  final String? nextCursor;

  /// `pageInfo.hasNextPage`.
  final bool hasNextPage;

  /// Contadores globales. Solo vienen en la primera pagina (sin `cursor`); en
  /// las siguientes es `null`.
  final DiscussionSummary? summary;
}
