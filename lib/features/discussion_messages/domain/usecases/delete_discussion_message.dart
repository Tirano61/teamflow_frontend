import '../../../../core/error/result.dart';
import '../repositories/discussion_message_repository.dart';

class DeleteDiscussionMessageParams {
  const DeleteDiscussionMessageParams({
    required this.discussionId,
    required this.messageId,
  });

  final String discussionId;
  final String messageId;
}

class DeleteDiscussionMessage {
  const DeleteDiscussionMessage(this._repository);

  final DiscussionMessageRepository _repository;

  Future<Result<void>> call(DeleteDiscussionMessageParams params) {
    return _repository.deleteMessage(
      discussionId: params.discussionId,
      messageId: params.messageId,
    );
  }
}
