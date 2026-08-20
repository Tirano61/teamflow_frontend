import '../../../../core/error/result.dart';
import '../entities/discussion.dart';
import '../repositories/discussion_repository.dart';

class CreateDiscussion {
  const CreateDiscussion(this._repository);

  final DiscussionRepository _repository;

  Future<Result<Discussion>> call(Discussion discussion) {
    return _repository.createDiscussion(discussion);
  }
}
