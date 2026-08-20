import '../../../../core/error/result.dart';
import '../entities/discussion_message.dart';
import '../repositories/discussion_message_repository.dart';

class UploadDiscussionMessageAttachmentParams {
  const UploadDiscussionMessageAttachmentParams({
    required this.discussionId,
    required this.type,
    required this.fileName,
    required this.fileBytes,
    this.content,
  });

  final String discussionId;
  final DiscussionMessageType type;
  final String fileName;
  final List<int> fileBytes;
  final String? content;
}

class UploadDiscussionMessageAttachment {
  const UploadDiscussionMessageAttachment(this._repository);

  final DiscussionMessageRepository _repository;

  Future<Result<DiscussionMessage>> call(
    UploadDiscussionMessageAttachmentParams params,
  ) {
    return _repository.createAttachmentMessage(
      discussionId: params.discussionId,
      type: params.type,
      fileName: params.fileName,
      fileBytes: params.fileBytes,
      content: params.content,
    );
  }
}
