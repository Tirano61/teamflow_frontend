import '../../../../core/error/result.dart';
import '../entities/discussion_filters.dart';
import '../entities/discussion_page.dart';
import '../repositories/discussion_repository.dart';

class GetDiscussions {
  const GetDiscussions(this._repository);

  final DiscussionRepository _repository;

  Future<Result<DiscussionPage>> call({
    DiscussionFilters filters = const DiscussionFilters(),
  }) {
    return _repository.getDiscussions(filters: filters);
  }
}
