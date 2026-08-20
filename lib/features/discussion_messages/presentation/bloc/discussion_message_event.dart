import '../../domain/entities/discussion_message.dart';

sealed class DiscussionMessageEvent {
  const DiscussionMessageEvent();
}

class LoadDiscussionMessagesEvent extends DiscussionMessageEvent {
  const LoadDiscussionMessagesEvent({
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

class LoadMoreDiscussionMessagesEvent extends DiscussionMessageEvent {
  const LoadMoreDiscussionMessagesEvent({
    required this.discussionId,
    this.limit = 50,
    this.type,
  });

  final String discussionId;
  final int limit;
  final DiscussionMessageType? type;
}

class RefreshDiscussionMessagesEvent extends DiscussionMessageEvent {
  const RefreshDiscussionMessagesEvent({
    required this.discussionId,
    this.limit = 50,
    this.type,
  });

  final String discussionId;
  final int limit;
  final DiscussionMessageType? type;
}

class CreateDiscussionMessageEvent extends DiscussionMessageEvent {
  const CreateDiscussionMessageEvent({
    required this.discussionId,
    required this.content,
    this.type = DiscussionMessageType.text,
  });

  final String discussionId;
  final String content;
  final DiscussionMessageType type;
}

class CreateDiscussionAttachmentMessageEvent extends DiscussionMessageEvent {
  const CreateDiscussionAttachmentMessageEvent({
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

class UpdateDiscussionMessageEvent extends DiscussionMessageEvent {
  const UpdateDiscussionMessageEvent({
    required this.discussionId,
    required this.messageId,
    required this.content,
  });

  final String discussionId;
  final String messageId;
  final String content;
}

class DeleteDiscussionMessageEvent extends DiscussionMessageEvent {
  const DeleteDiscussionMessageEvent({
    required this.discussionId,
    required this.messageId,
  });

  final String discussionId;
  final String messageId;
}
