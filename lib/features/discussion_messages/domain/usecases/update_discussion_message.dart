import '../../../../core/error/result.dart';
import '../entities/discussion_message.dart';
import '../repositories/discussion_message_repository.dart';

class UpdateDiscussionMessageParams {
  const UpdateDiscussionMessageParams({
    required this.discussionId,
    required this.messageId,
    required this.content,
  });

  final String discussionId;
  final String messageId;
  final String content;
}

class UpdateDiscussionMessage {
  const UpdateDiscussionMessage(this._repository);

  final DiscussionMessageRepository _repository;

  Future<Result<DiscussionMessage>> call(UpdateDiscussionMessageParams params) {
    return _repository.updateMessage(
      discussionId: params.discussionId,
      messageId: params.messageId,
      content: params.content,
    );
  }
}
