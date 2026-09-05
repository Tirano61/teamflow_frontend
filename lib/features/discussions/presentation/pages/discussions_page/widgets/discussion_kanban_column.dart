import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/discussion.dart';
import '../../../bloc/discussion_state.dart';
import '../../../widgets/discussion_board_card.dart';
import '../discussions_helpers.dart';

/// Columna del tablero kanban con las discussions de un estado.
class DiscussionKanbanColumn extends StatelessWidget {
  const DiscussionKanbanColumn({
    required this.title,
    required this.accent,
    required this.items,
    required this.state,
    required this.isDeveloper,
    required this.onOpen,
    required this.onManageAssignments,
    required this.onAssignToMe,
    required this.onChangeStatus,
    super.key,
  });

  final String title;
  final Color accent;
  final List<Discussion> items;
  final DiscussionState state;
  final bool isDeveloper;
  final Future<void> Function({required String? discussionId}) onOpen;
  final Future<void> Function(Discussion discussion) onManageAssignments;
  final void Function(Discussion discussion) onAssignToMe;
  final void Function(Discussion discussion, DiscussionRecordStatus nextStatus)
  onChangeStatus;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '${items.length}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: accent),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).colorScheme.outline),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'Sin discussions',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final discussion = items[index];
                        return DiscussionBoardCard(
                          discussion: discussion,
                          isDeveloper: isDeveloper,
                          isBusy: isDiscussionBusy(state, discussion.id),
                          onOpen: () => onOpen(discussionId: discussion.id),
                          onManageAssignments: () =>
                              onManageAssignments(discussion),
                          onAssignToMe: () => onAssignToMe(discussion),
                          onChangeStatus: (nextStatus) =>
                              onChangeStatus(discussion, nextStatus),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
