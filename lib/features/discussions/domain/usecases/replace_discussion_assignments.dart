import '../../../../core/error/result.dart';
import '../entities/discussion.dart';
import '../repositories/discussion_repository.dart';

class ReplaceDiscussionAssignments {
  const ReplaceDiscussionAssignments(this._repository);

  final DiscussionRepository _repository;

  Future<Result<Discussion>> call({
    required String discussionId,
    required List<String> developerUserIds,
  }) {
    return _repository.replaceDiscussionAssignments(
      discussionId: discussionId,
      developerUserIds: developerUserIds,
    );
  }
}
