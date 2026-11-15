import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/discussion.dart';
import '../../../../domain/entities/discussion_permissions.dart';
import '../../../bloc/discussion_state.dart';
import '../discussions_helpers.dart';
import 'discussion_infinite_scroll.dart';
import 'discussion_kanban_column.dart';

/// Tablero kanban con las cuatro columnas de estados. Las discussions vienen
/// de un unico recorrido paginado (sin filtro `status`) repartido por estado.
/// Cada columna incompleta pide mas para si misma (ver
/// [DiscussionKanbanColumn]); el tablero solo pide una pagina cuando ninguna
/// columna tiene contenido suficiente para desplazarse (pantallas altas).
class DiscussionKanbanBoard extends StatelessWidget {
  const DiscussionKanbanBoard({
    required this.grouped,
    required this.state,
    required this.permissions,
    required this.onOpen,
    required this.onManageAssignments,
    required this.onAssignToMe,
    required this.onChangeStatus,
    required this.onLoadMore,
    this.useOuterPadding = true,
    super.key,
  });

  final Map<DiscussionRecordStatus, List<Discussion>> grouped;
  final DiscussionState state;
  final DiscussionPermissions permissions;
  final bool useOuterPadding;
  final Future<void> Function({required String? discussionId}) onOpen;
  final Future<void> Function(Discussion discussion) onManageAssignments;
  final void Function(Discussion discussion) onAssignToMe;
  final void Function(Discussion discussion, DiscussionRecordStatus nextStatus)
  onChangeStatus;

  /// `status` es la columna que pide mas; `null` para una sola pagina.
  final void Function(DiscussionRecordStatus? status) onLoadMore;

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
            status: columns[index].status,
            title: columns[index].title,
            accent: columns[index].accent,
            items: discussionsForStatus(grouped, columns[index].status),
            state: state,
            permissions: permissions,
            onOpen: onOpen,
            onAssignToMe: onAssignToMe,
            onManageAssignments: onManageAssignments,
            onChangeStatus: onChangeStatus,
            onLoadMore: onLoadMore,
          ),
        ],
      ],
    );

    final scrollableBoard = DiscussionInfiniteScroll(
      enabled: state.canLoadNextPage,
      loadedCount: state.discussions.length,
      loadOnScrollEnd: false,
      onLoadMore: () => onLoadMore(null),
      child: board,
    );

    if (!useOuterPadding) {
      return scrollableBoard;
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: scrollableBoard,
    );
  }
}
