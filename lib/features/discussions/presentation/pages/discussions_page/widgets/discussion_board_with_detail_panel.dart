import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/discussion.dart';
import '../../../bloc/discussion_state.dart';
import '../../discussion_detail_page/discussion_detail_page.dart';
import 'discussion_kanban_board.dart';

/// Tablero kanban con el panel lateral de detalle en pantallas anchas.
class DiscussionBoardWithDetailPanel extends StatelessWidget {
  const DiscussionBoardWithDetailPanel({
    required this.grouped,
    required this.state,
    required this.isDeveloper,
    required this.useDetailPanel,
    required this.maxWidth,
    required this.activeDiscussionId,
    required this.onCloseDetail,
    required this.onOpen,
    required this.onManageAssignments,
    required this.onAssignToMe,
    required this.onChangeStatus,
    super.key,
  });

  final Map<DiscussionRecordStatus, List<Discussion>> grouped;
  final DiscussionState state;
  final bool isDeveloper;
  final bool useDetailPanel;
  final double maxWidth;
  final String? activeDiscussionId;
  final VoidCallback onCloseDetail;
  final Future<void> Function({required String? discussionId}) onOpen;
  final Future<void> Function(Discussion discussion) onManageAssignments;
  final void Function(Discussion discussion) onAssignToMe;
  final void Function(Discussion discussion, DiscussionRecordStatus nextStatus)
  onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final discussionId = activeDiscussionId;

    if (!useDetailPanel || discussionId == null) {
      return DiscussionKanbanBoard(
        grouped: grouped,
        state: state,
        isDeveloper: isDeveloper,
        onOpen: onOpen,
        onAssignToMe: onAssignToMe,
        onManageAssignments: onManageAssignments,
        onChangeStatus: onChangeStatus,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DiscussionKanbanBoard(
              grouped: grouped,
              state: state,
              isDeveloper: isDeveloper,
              useOuterPadding: false,
              onOpen: onOpen,
              onAssignToMe: onAssignToMe,
              onManageAssignments: onManageAssignments,
              onChangeStatus: onChangeStatus,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(
            width: _panelWidth(maxWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: DiscussionDetailPage(
                  key: ValueKey<String>(discussionId),
                  discussionId: discussionId,
                  embedded: true,
                  onClose: onCloseDetail,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _panelWidth(double maxWidth) {
    final width = maxWidth * 0.36;
    if (width < 560) {
      return 560;
    }
    if (width > 760) {
      return 760;
    }
    return width;
  }
}
