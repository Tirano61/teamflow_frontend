import '../../../../core/error/result.dart';
import '../entities/discussion_filters.dart';
import '../entities/discussion_page.dart';
import '../repositories/discussion_repository.dart';

class GetDiscussions {
  const GetDiscussions(this._repository);

  final DiscussionRepository _repository;

  /// Sin [cursor] devuelve la primera pagina (con `summary`); con el
  /// `nextCursor` de la pagina anterior y los mismos [filters], la siguiente.
  Future<Result<DiscussionPage>> call({
    DiscussionFilters filters = const DiscussionFilters(),
    String? cursor,
  }) {
    return _repository.getDiscussions(filters: filters, cursor: cursor);
  }
}
