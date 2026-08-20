import 'package:receive_sharing_intent/receive_sharing_intent.dart';

sealed class ShareIntentEvent {
  const ShareIntentEvent();
}

class InitializeShareIntentEvent extends ShareIntentEvent {
  const InitializeShareIntentEvent();
}

class ShareIntentAuthStatusChangedEvent extends ShareIntentEvent {
  const ShareIntentAuthStatusChangedEvent({required this.isAuthenticated});

  final bool isAuthenticated;
}

class ShareIntentMediaReceivedEvent extends ShareIntentEvent {
  const ShareIntentMediaReceivedEvent({
    required this.files,
    required this.origin,
  });

  final List<SharedMediaFile> files;
  final String origin;
}

class ShareIntentLoadDiscussionsEvent extends ShareIntentEvent {
  const ShareIntentLoadDiscussionsEvent({this.preferredDiscussionId});

  final String? preferredDiscussionId;
}

class ShareIntentSearchChangedEvent extends ShareIntentEvent {
  const ShareIntentSearchChangedEvent(this.query);

  final String query;
}

class ShareIntentDiscussionSelectedEvent extends ShareIntentEvent {
  const ShareIntentDiscussionSelectedEvent(this.discussionId);

  final String? discussionId;
}

class ShareIntentSendRequestedEvent extends ShareIntentEvent {
  const ShareIntentSendRequestedEvent();
}

class ShareIntentCancelEvent extends ShareIntentEvent {
  const ShareIntentCancelEvent();
}

class ShareIntentMessageConsumedEvent extends ShareIntentEvent {
  const ShareIntentMessageConsumedEvent();
}
