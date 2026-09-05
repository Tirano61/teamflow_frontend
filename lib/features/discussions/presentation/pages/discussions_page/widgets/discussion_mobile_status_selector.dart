import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/discussion.dart';
import '../discussions_helpers.dart';

/// Selector horizontal de estados usado en el layout compacto.
class DiscussionMobileStatusSelector extends StatelessWidget {
  const DiscussionMobileStatusSelector({
    required this.grouped,
    required this.currentStatus,
    required this.onStatusSelected,
    super.key,
  });

  final Map<DiscussionRecordStatus, List<Discussion>> grouped;
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
                label: Text(
                  '${entry.$2} ${discussionsForStatus(grouped, entry.$1).length}',
                ),
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
}
