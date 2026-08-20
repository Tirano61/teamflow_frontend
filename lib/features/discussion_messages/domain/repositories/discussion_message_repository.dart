import '../../../../core/error/result.dart';
import '../entities/discussion_message.dart';
import '../entities/discussion_message_page.dart';

abstract class DiscussionMessageRepository {
  Future<Result<DiscussionMessagePage>> getMessagesByDiscussion({
    required String discussionId,
    int page = 1,
    int limit = 50,
    DiscussionMessageType? type,
  });

  Future<Result<DiscussionMessage>> createMessage({
    required String discussionId,
    required DiscussionMessageType type,
    required String content,
  });

  Future<Result<DiscussionMessage>> createAttachmentMessage({
    required String discussionId,
    required DiscussionMessageType type,
    required String fileName,
    required List<int> fileBytes,
    String? content,
  });

  Future<Result<DiscussionMessage>> updateMessage({
    required String discussionId,
    required String messageId,
    required String content,
  });

  Future<Result<void>> deleteMessage({
    required String discussionId,
    required String messageId,
  });
}
