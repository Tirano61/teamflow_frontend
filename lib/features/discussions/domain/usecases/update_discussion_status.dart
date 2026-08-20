import '../../../../core/error/result.dart';
import '../entities/discussion.dart';
import '../repositories/discussion_repository.dart';

class UpdateDiscussionStatus {
  const UpdateDiscussionStatus(this._repository);

  final DiscussionRepository _repository;

  Future<Result<Discussion>> call({
    required String discussionId,
    required DiscussionRecordStatus status,
  }) {
    return _repository.updateDiscussionStatus(
      discussionId: discussionId,
      status: status,
    );
  }
}
