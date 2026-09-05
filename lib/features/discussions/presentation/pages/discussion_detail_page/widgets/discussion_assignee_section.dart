import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/discussion.dart';
import '../../../../domain/entities/discussion_developer.dart';
import '../discussion_detail_helpers.dart';
import 'discussion_person_pill.dart';

class DiscussionAssigneeSection extends StatelessWidget {
  const DiscussionAssigneeSection({
    required this.discussion,
    required this.isDeveloper,
    required this.disabled,
    required this.onOpenAssignments,
    super.key,
  });

  final Discussion discussion;
  final bool isDeveloper;
  final bool disabled;
  final VoidCallback onOpenAssignments;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDeveloper && !disabled ? onOpenAssignments : null,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Row(
        children: [
          const Icon(Icons.groups_2_outlined, size: 16),
          const SizedBox(width: AppSpacing.xs),
          if (discussion.assignedDevelopers.isEmpty)
            Text(
              'Sin asignar',
              style: Theme.of(context).textTheme.labelMedium,
            )
          else
            Flexible(
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: _buildAssigneeChips(
                  context,
                  discussion.assignedDevelopers,
                ),
              ),
            ),
          if (isDeveloper) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(
              isCompactLayout(context)
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.edit_outlined,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildAssigneeChips(
    BuildContext context,
    List<DiscussionAssignedDeveloper> assignees,
  ) {
    const visibleCount = 4;
    final visible = assignees.take(visibleCount).toList(growable: false);
    final overflow = assignees.length - visible.length;

    final chips = <Widget>[];
    for (final assignee in visible) {
      chips.add(
        Tooltip(
          message: assignee.fullName,
          child: DiscussionPersonPill(
            name: assignee.fullName,
            borderColor: Theme.of(context).colorScheme.outline,
            avatarBackground:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            avatarTextColor: Theme.of(context).textTheme.labelSmall?.color,
            textColor: Theme.of(context).textTheme.labelSmall?.color,
          ),
        ),
      );
    }

    if (overflow > 0) {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Text(
            '+$overflow',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      );
    }

    return chips;
  }
}
