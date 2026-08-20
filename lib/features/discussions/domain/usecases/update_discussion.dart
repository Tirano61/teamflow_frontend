import '../../../../core/error/result.dart';
import '../entities/discussion.dart';
import '../repositories/discussion_repository.dart';

class UpdateDiscussion {
  const UpdateDiscussion(this._repository);

  final DiscussionRepository _repository;

  Future<Result<Discussion>> call(Discussion discussion) {
    return _repository.updateDiscussion(discussion);
  }
}
