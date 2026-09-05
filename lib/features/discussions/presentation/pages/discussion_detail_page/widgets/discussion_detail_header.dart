import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/discussion.dart';
import '../discussion_detail_helpers.dart';
import 'discussion_assignee_section.dart';
import 'discussion_context_chips.dart';
import 'discussion_person_pill.dart';
import 'discussion_status_control.dart';
import 'discussion_type_chip.dart';

class DiscussionDetailHeader extends StatelessWidget {
  const DiscussionDetailHeader({
    required this.discussion,
    required this.isDeveloper,
    required this.statusBusy,
    required this.assigneesBusy,
    required this.isSending,
    required this.embedded,
    required this.workModuleLabels,
    required this.componentLabels,
    required this.onStatusSelected,
    required this.onOpenStatusSheet,
    required this.onOpenAssignments,
    required this.onOpenWorkModuleSelector,
    required this.onOpenComponentSelector,
    this.onClose,
    super.key,
  });

  final Discussion discussion;
  final bool isDeveloper;
  final bool statusBusy;
  final bool assigneesBusy;
  final bool isSending;
  final bool embedded;
  final List<String> workModuleLabels;
  final List<String> componentLabels;
  final ValueChanged<DiscussionRecordStatus> onStatusSelected;
  final VoidCallback onOpenStatusSheet;
  final VoidCallback onOpenAssignments;
  final VoidCallback onOpenWorkModuleSelector;
  final VoidCallback onOpenComponentSelector;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DiscussionTypeChip(type: discussion.type),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Canal:',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  DiscussionStatusControl(
                    discussion: discussion,
                    isDeveloper: isDeveloper,
                    disabled: statusBusy || isSending,
                    onStatusSelected: onStatusSelected,
                    onOpenStatusSheet: onOpenStatusSheet,
                  ),
                ],
              ),
              Text(
                formatShortDateTime(discussion.updatedAt ?? discussion.createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (embedded) ...[
                IconButton(
                  tooltip: 'Cerrar panel',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            normalizedDiscussionTitle(discussion.title),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              ...buildDiscussionContextChips(
                label: 'Aplicacion',
                values: workModuleLabels,
                emptyLabel: 'Sin aplicaciÃ³n',
                onTap: isDeveloper ? onOpenWorkModuleSelector : null,
              ),
              ...buildDiscussionContextChips(
                label: 'Indicador',
                values: componentLabels,
                emptyLabel: 'Sin indicador',
                onTap: isDeveloper ? onOpenComponentSelector : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DiscussionAssigneeSection(
                      discussion: discussion,
                      isDeveloper: isDeveloper,
                      disabled: assigneesBusy,
                      onOpenAssignments: onOpenAssignments,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Creado por:',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        DiscussionPersonPill(
                          name: creatorDisplayName(discussion.createdBy),
                          borderColor: Theme.of(context).colorScheme.outline,
                          avatarBackground: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          avatarTextColor:
                              Theme.of(context).textTheme.labelSmall?.color,
                          textColor:
                              Theme.of(context).textTheme.labelSmall?.color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSending || statusBusy || assigneesBusy)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
