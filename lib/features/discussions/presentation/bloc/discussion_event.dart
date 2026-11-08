import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_changes.dart';
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
  const UpdateDiscussionEvent({
    required this.discussionId,
    required this.changes,
  });

  final String discussionId;

  /// Solo los campos modificados (ver [DiscussionChanges]). Incluir
  /// `moduleIds`/`componentIds`/`tagIds` requiere rol de gestion: quien
  /// despacha lo decide con `DiscussionPermissions.canManageContext`. Sin
  /// cambios no se envia el PATCH.
  final DiscussionChanges changes;
}

/// Discussion que el backend ya confirmo en otra ruta (respuesta del `POST` o
/// `PATCH` del editor). Se incorpora al estado sin volver a pedirla.
class DiscussionSavedEvent extends DiscussionEvent {
  const DiscussionSavedEvent(this.discussion, {this.created = false});

  final Discussion discussion;

  /// `true` si viene del `POST` de creacion (el creador es el usuario
  /// autenticado y la respuesta ya trae `isUnread`).
  final bool created;
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
