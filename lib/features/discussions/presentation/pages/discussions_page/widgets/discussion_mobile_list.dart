import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/discussion.dart';
import '../../../../domain/entities/discussion_permissions.dart';
import '../../../bloc/discussion_state.dart';
import '../../../widgets/discussion_board_card.dart';
import '../discussions_helpers.dart';
import 'discussion_infinite_scroll.dart';
import 'discussion_load_more_footer.dart';

/// Listado vertical de discussions usado en el layout compacto: un recorrido
/// paginado filtrado por el estado elegido, con scroll infinito.
class DiscussionMobileList extends StatelessWidget {
  const DiscussionMobileList({
    required this.items,
    required this.state,
    required this.permissions,
    required this.currentStatusLabel,
    required this.onOpen,
    required this.onManageAssignments,
    required this.onAssignToMe,
    required this.onChangeStatus,
    required this.onLoadMore,
    super.key,
  });

  final List<Discussion> items;
  final DiscussionState state;
  final DiscussionPermissions permissions;
  final String currentStatusLabel;
  final Future<void> Function({required String? discussionId}) onOpen;
  final Future<void> Function(Discussion discussion) onManageAssignments;
  final void Function(Discussion discussion) onAssignToMe;
  final void Function(Discussion discussion, DiscussionRecordStatus nextStatus)
  onChangeStatus;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final showFooter = DiscussionLoadMoreFooter.isVisible(state);

    if (items.isEmpty && !showFooter) {
      return Center(
        child: Text(
          'Sin discussions en ${currentStatusLabel.toLowerCase()}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return DiscussionInfiniteScroll(
      enabled: state.canLoadNextPage,
      loadedCount: state.discussions.length,
      onLoadMore: onLoadMore,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
            onManageAssignments: () => onManageAssignments(discussion),
            onAssignToMe: () => onAssignToMe(discussion),
            onChangeStatus: (nextStatus) =>
                onChangeStatus(discussion, nextStatus),
          );
        },
      ),
    );
  }
}
