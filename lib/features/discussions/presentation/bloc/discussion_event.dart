import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_filters.dart';

sealed class DiscussionEvent {
  const DiscussionEvent();
}

class LoadDiscussionsEvent extends DiscussionEvent {
  const LoadDiscussionsEvent({
    this.filters = const DiscussionFilters(),
    this.silent = false,
  });

  final DiscussionFilters filters;
  final bool silent;
}

class LoadDiscussionEvent extends DiscussionEvent {
  const LoadDiscussionEvent(this.id);

  final String id;
}

class MarkDiscussionAsReadEvent extends DiscussionEvent {
  const MarkDiscussionAsReadEvent(this.discussionId);

  final String discussionId;
}

class CreateDiscussionEvent extends DiscussionEvent {
  const CreateDiscussionEvent(this.discussion);

  final Discussion discussion;
}

class UpdateDiscussionEvent extends DiscussionEvent {
  const UpdateDiscussionEvent(this.discussion);

  final Discussion discussion;
}

class SelectDiscussionEvent extends DiscussionEvent {
  const SelectDiscussionEvent(this.discussionId);

  final String? discussionId;
}

class LoadAssignableDevelopersEvent extends DiscussionEvent {
  const LoadAssignableDevelopersEvent({this.forceReload = false});

  final bool forceReload;
}

class ChangeDiscussionStatusEvent extends DiscussionEvent {
  const ChangeDiscussionStatusEvent({
    required this.discussionId,
    required this.status,
  });

  final String discussionId;
  final DiscussionRecordStatus status;
}

class AddDiscussionAssignmentsEvent extends DiscussionEvent {
  const AddDiscussionAssignmentsEvent({
    required this.discussionId,
    required this.developerUserIds,
  });

  final String discussionId;
  final List<String> developerUserIds;
}

class ReplaceDiscussionAssignmentsEvent extends DiscussionEvent {
  const ReplaceDiscussionAssignmentsEvent({
    required this.discussionId,
    required this.developerUserIds,
  });

  final String discussionId;
  final List<String> developerUserIds;
}

class RemoveDiscussionAssignmentEvent extends DiscussionEvent {
  const RemoveDiscussionAssignmentEvent({
    required this.discussionId,
    required this.developerUserId,
  });

  final String discussionId;
  final String developerUserId;
}

class AssignDiscussionToMeEvent extends DiscussionEvent {
  const AssignDiscussionToMeEvent({
    required this.discussionId,
    required this.currentDeveloperUserId,
  });

  final String discussionId;
  final String currentDeveloperUserId;
}

class ClearDiscussionOperationMessageEvent extends DiscussionEvent {
  const ClearDiscussionOperationMessageEvent();
}
