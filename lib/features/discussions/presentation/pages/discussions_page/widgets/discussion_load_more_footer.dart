import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../bloc/discussion_state.dart';

/// Pie de un listado paginado: indicador mientras llega la pagina siguiente,
/// reintento si fallo, o accion para pedirla si todavia no se pidio.
class DiscussionLoadMoreFooter extends StatelessWidget {
  const DiscussionLoadMoreFooter({
    required this.state,
    required this.onLoadMore,
    this.progressLabel,
    super.key,
  });

  final DiscussionState state;
  final VoidCallback onLoadMore;

  /// Cuantas hay cargadas respecto del total (columnas del kanban).
  final String? progressLabel;

  /// El listado tiene algo que mostrar al final.
  static bool isVisible(DiscussionState state) {
    return state.hasNextPage ||
        state.isLoadingNextPage ||
        state.nextPageErrorMessage.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (state.isLoadingNextPage) {
      content = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (state.nextPageErrorMessage.isNotEmpty) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No se pudieron cargar más discussions.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          TextButton.icon(
            onPressed: onLoadMore,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      );
    } else if (state.hasNextPage) {
      final label = progressLabel;
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          TextButton(onPressed: onLoadMore, child: const Text('Cargar más')),
        ],
      );
    } else {
      content = const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(child: content),
    );
  }
}
