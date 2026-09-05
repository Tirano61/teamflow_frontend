import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/discussion.dart';
import '../../../bloc/discussion_state.dart';
import '../../../widgets/discussion_board_card.dart';
import '../discussions_helpers.dart';

/// Listado vertical de discussions usado en el layout compacto.
class DiscussionMobileList extends StatelessWidget {
  const DiscussionMobileList({
    required this.items,
    required this.state,
    required this.isDeveloper,
    required this.currentStatusLabel,
    required this.onOpen,
    required this.onManageAssignments,
    required this.onAssignToMe,
    required this.onChangeStatus,
    super.key,
  });

  final List<Discussion> items;
  final DiscussionState state;
  final bool isDeveloper;
  final String currentStatusLabel;
  final Future<void> Function({required String? discussionId}) onOpen;
  final Future<void> Function(Discussion discussion) onManageAssignments;
  final void Function(Discussion discussion) onAssignToMe;
  final void Function(Discussion discussion, DiscussionRecordStatus nextStatus)
  onChangeStatus;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Sin discussions en ${currentStatusLabel.toLowerCase()}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final discussion = items[index];
        return DiscussionBoardCard(
          discussion: discussion,
          isDeveloper: isDeveloper,
          isBusy: isDiscussionBusy(state, discussion.id),
          onOpen: () => onOpen(discussionId: discussion.id),
          onManageAssignments: () => onManageAssignments(discussion),
          onAssignToMe: () => onAssignToMe(discussion),
          onChangeStatus: (nextStatus) =>
              onChangeStatus(discussion, nextStatus),
        );
      },
    );
  }
}
