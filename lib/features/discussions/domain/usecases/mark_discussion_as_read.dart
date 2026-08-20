import '../../../../core/error/result.dart';
import '../entities/discussion.dart';
import '../repositories/discussion_repository.dart';

class MarkDiscussionAsRead {
  const MarkDiscussionAsRead(this._repository);

  final DiscussionRepository _repository;

  Future<Result<DiscussionReadState>> call(String discussionId) {
    return _repository.markDiscussionAsRead(discussionId);
  }
}
