import '../../../../core/error/result.dart';
import '../entities/discussion.dart';
import '../repositories/discussion_repository.dart';

class GetDiscussion {
  const GetDiscussion(this._repository);

  final DiscussionRepository _repository;

  Future<Result<Discussion>> call(String id) {
    return _repository.getDiscussionById(id);
  }
}
