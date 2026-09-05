import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/discussion.dart';
import '../../../bloc/discussion_state.dart';
import '../discussions_helpers.dart';
import 'discussion_kanban_column.dart';

/// Tablero kanban con las cuatro columnas de estados.
class DiscussionKanbanBoard extends StatelessWidget {
  const DiscussionKanbanBoard({
    required this.grouped,
    required this.state,
    required this.isDeveloper,
    required this.onOpen,
    required this.onManageAssignments,
    required this.onAssignToMe,
    required this.onChangeStatus,
    this.useOuterPadding = true,
    super.key,
  });

  final Map<DiscussionRecordStatus, List<Discussion>> grouped;
  final DiscussionState state;
  final bool isDeveloper;
  final bool useOuterPadding;
  final Future<void> Function({required String? discussionId}) onOpen;
  final Future<void> Function(Discussion discussion) onManageAssignments;
  final void Function(Discussion discussion) onAssignToMe;
  final void Function(Discussion discussion, DiscussionRecordStatus nextStatus)
  onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final columns =
        <({DiscussionRecordStatus status, String title, Color accent})>[
          (
            status: DiscussionRecordStatus.newDiscussion,
            title: 'Entrada',
            accent: semantic.statusNew,
          ),
          (
            status: DiscussionRecordStatus.review,
            title: 'Revisión',
            accent: semantic.statusReview,
          ),
          (
            status: DiscussionRecordStatus.inProgress,
            title: 'Trabajando',
            accent: semantic.statusInProgress,
          ),
          (
            status: DiscussionRecordStatus.resolved,
            title: 'Resuelto',
            accent: semantic.statusResolved,
          ),
        ];

    final board = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < columns.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.sm),
          DiscussionKanbanColumn(
            title: columns[index].title,
            accent: columns[index].accent,
            items: discussionsForStatus(grouped, columns[index].status),
            state: state,
            isDeveloper: isDeveloper,
            onOpen: onOpen,
            onAssignToMe: onAssignToMe,
            onManageAssignments: onManageAssignments,
            onChangeStatus: onChangeStatus,
          ),
        ],
      ],
    );

    if (!useOuterPadding) {
      return board;
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: board,
    );
  }
}
