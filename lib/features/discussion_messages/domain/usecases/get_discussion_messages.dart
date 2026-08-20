import '../../../../core/error/result.dart';
import '../entities/discussion_message.dart';
import '../entities/discussion_message_page.dart';
import '../repositories/discussion_message_repository.dart';

class GetDiscussionMessagesParams {
  const GetDiscussionMessagesParams({
    required this.discussionId,
    this.page = 1,
    this.limit = 50,
    this.type,
  });

  final String discussionId;
  final int page;
  final int limit;
  final DiscussionMessageType? type;
}

class GetDiscussionMessages {
  const GetDiscussionMessages(this._repository);

  final DiscussionMessageRepository _repository;

  Future<Result<DiscussionMessagePage>> call(
    GetDiscussionMessagesParams params,
  ) {
    return _repository.getMessagesByDiscussion(
      discussionId: params.discussionId,
      page: params.page,
      limit: params.limit,
      type: params.type,
    );
  }
}
