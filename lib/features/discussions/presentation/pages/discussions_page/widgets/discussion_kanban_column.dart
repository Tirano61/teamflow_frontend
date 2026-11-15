import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/discussion.dart';
import '../../../../domain/entities/discussion_permissions.dart';
import '../../../bloc/discussion_state.dart';
import '../../../widgets/discussion_board_card.dart';
import '../discussions_helpers.dart';
import 'discussion_load_more_footer.dart';

/// Columna del tablero kanban con las discussions cargadas de un estado.
///
/// El contador es el global del backend (`summary.byStatus`), no la cantidad
/// de discussions descargadas.
class DiscussionKanbanColumn extends StatelessWidget {
  const DiscussionKanbanColumn({
    required this.status,
    required this.title,
    required this.accent,
    required this.items,
    required this.state,
    required this.permissions,
    required this.onOpen,
    required this.onManageAssignments,
    required this.onAssignToMe,
    required this.onChangeStatus,
    required this.onLoadMore,
    super.key,
  });

  final DiscussionRecordStatus status;
  final String title;
  final Color accent;
  final List<Discussion> items;
  final DiscussionState state;
  final DiscussionPermissions permissions;
  final Future<void> Function({required String? discussionId}) onOpen;
  final Future<void> Function(Discussion discussion) onManageAssignments;
  final void Function(Discussion discussion) onAssignToMe;
  final void Function(Discussion discussion, DiscussionRecordStatus nextStatus)
  onChangeStatus;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final count = state.summary?.countFor(status);
    final showFooter = DiscussionLoadMoreFooter.isVisible(state);

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
                  if (count != null)
                    Text(
                      '$count',
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: accent),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).colorScheme.outline),
            Expanded(
              child: items.isEmpty && !showFooter
                  ? Center(
                      child: Text(
                        'Sin discussions',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      itemCount: items.length + (showFooter ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == items.length) {
                          return DiscussionLoadMoreFooter(
                            state: state,
                            onLoadMore: onLoadMore,
                          );
                        }

                        final discussion = items[index];
                        return DiscussionBoardCard(
                          discussion: discussion,
                          permissions: permissions,
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
