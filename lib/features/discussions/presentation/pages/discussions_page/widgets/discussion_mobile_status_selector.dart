import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/discussion.dart';
import '../../../../domain/entities/discussion_summary.dart';

/// Selector horizontal de estados usado en el layout compacto. Elegir un
/// estado filtra el listado en el backend; los contadores son los globales
/// (`summary.byStatus`, que no depende del filtro `status`).
class DiscussionMobileStatusSelector extends StatelessWidget {
  const DiscussionMobileStatusSelector({
    required this.summary,
    required this.currentStatus,
    required this.onStatusSelected,
    super.key,
  });

  /// `null` mientras no hay contadores validos para los filtros vigentes.
  final DiscussionSummary? summary;
  final DiscussionRecordStatus currentStatus;
  final ValueChanged<DiscussionRecordStatus> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final entries = <(DiscussionRecordStatus, String)>[
      (DiscussionRecordStatus.newDiscussion, 'Entrada'),
      (DiscussionRecordStatus.review, 'Revisión'),
      (DiscussionRecordStatus.inProgress, 'Trabajando'),
      (DiscussionRecordStatus.resolved, 'Resuelto'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final entry in entries) ...[
              ChoiceChip(
                label: Text(_label(entry.$2, entry.$1)),
                selected: currentStatus == entry.$1,
                onSelected: (_) => onStatusSelected(entry.$1),
              ),
              if (entry != entries.last) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  String _label(String title, DiscussionRecordStatus status) {
    final counts = summary;
    if (counts == null) {
      return title;
    }
    return '$title ${counts.countFor(status)}';
  }
}
