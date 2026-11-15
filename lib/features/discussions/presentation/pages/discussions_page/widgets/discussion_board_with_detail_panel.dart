import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../discussion_detail_page/discussion_detail_page.dart';

/// Tablero kanban con el panel lateral de detalle en pantallas anchas.
///
/// El tablero ocupa siempre la misma posicion del arbol, abierto o no el
/// panel, para que sus columnas conserven el scroll y las paginas cargadas.
class DiscussionBoardWithDetailPanel extends StatelessWidget {
  const DiscussionBoardWithDetailPanel({
    required this.board,
    required this.useDetailPanel,
    required this.maxWidth,
    required this.activeDiscussionId,
    required this.onCloseDetail,
    super.key,
  });

  /// Kanban (o su estado de carga/error), sin padding exterior.
  final Widget board;
  final bool useDetailPanel;
  final double maxWidth;
  final String? activeDiscussionId;
  final VoidCallback onCloseDetail;

  @override
  Widget build(BuildContext context) {
    final discussionId = useDetailPanel ? activeDiscussionId : null;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: board),
          if (discussionId != null) ...[
            const SizedBox(width: AppSpacing.lg),
            SizedBox(
              width: _panelWidth(maxWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
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
