import '../../../../core/error/result.dart';
import '../entities/discussion_message.dart';
import '../repositories/discussion_message_repository.dart';

class CreateDiscussionMessageParams {
  const CreateDiscussionMessageParams({
    required this.discussionId,
    required this.content,
    this.type = DiscussionMessageType.text,
  });

  final String discussionId;
  final String content;
  final DiscussionMessageType type;
}

class CreateDiscussionMessage {
  const CreateDiscussionMessage(this._repository);

  final DiscussionMessageRepository _repository;

  Future<Result<DiscussionMessage>> call(CreateDiscussionMessageParams params) {
    return _repository.createMessage(
      discussionId: params.discussionId,
      type: params.type,
      content: params.content,
    );
  }
}
