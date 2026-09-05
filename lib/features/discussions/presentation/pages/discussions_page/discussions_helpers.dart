import '../../../domain/entities/discussion.dart';
import '../../bloc/discussion_state.dart';

/// Agrupa las discussions por estado para armar las columnas del tablero.
Map<DiscussionRecordStatus, List<Discussion>> groupDiscussionsByStatus(
  List<Discussion> discussions,
) {
  final grouped = <DiscussionRecordStatus, List<Discussion>>{
    DiscussionRecordStatus.newDiscussion: <Discussion>[],
    DiscussionRecordStatus.review: <Discussion>[],
    DiscussionRecordStatus.inProgress: <Discussion>[],
    DiscussionRecordStatus.resolved: <Discussion>[],
  };

  for (final discussion in discussions) {
    final status = discussion.status;
    if (!grouped.containsKey(status)) {
      continue;
    }
    grouped[status]!.add(discussion);
  }

  return grouped;
}

List<Discussion> discussionsForStatus(
  Map<DiscussionRecordStatus, List<Discussion>> grouped,
  DiscussionRecordStatus status,
) {
  return grouped[status] ?? const <Discussion>[];
}

/// Indica si la discussion tiene una operacion de asignacion o estado en curso.
bool isDiscussionBusy(DiscussionState state, String? discussionId) {
  if (discussionId == null || discussionId.isEmpty) {
    return false;
  }

  return state.operationDiscussionId == discussionId &&
      (state.isUpdatingAssignments || state.isUpdatingStatus);
}
