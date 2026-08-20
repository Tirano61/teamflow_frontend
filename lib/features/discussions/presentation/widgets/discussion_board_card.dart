import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_developer.dart';

class DiscussionBoardCard extends StatelessWidget {
  const DiscussionBoardCard({
    required this.discussion,
    required this.isDeveloper,
    required this.isBusy,
    required this.onOpen,
    required this.onManageAssignments,
    required this.onAssignToMe,
    required this.onChangeStatus,
    super.key,
  });

  final Discussion discussion;
  final bool isDeveloper;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onManageAssignments;
  final VoidCallback onAssignToMe;
  final void Function(DiscussionRecordStatus status) onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final title = discussion.title.trim().isEmpty
        ? '(Sin titulo)'
        : discussion.title.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _DwTypeChip(type: discussion.type),
                  const Spacer(),
                  _DwCreatorMeta(creator: discussion.createdBy),
                  const SizedBox(width: AppSpacing.sm),
                  _DwUnreadIndicator(isUnread: discussion.isUnread),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: discussion.isUnread
                    ? Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )
                    : Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              _DwContextChips(discussion: discussion),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DwAssigneeChips(
                      assignees: discussion.assignedDevelopers,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _relativeActivity(discussion),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
              if (isDeveloper) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      onPressed: isBusy ? null : onAssignToMe,
                      tooltip: 'Asignarme',
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.outline),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                      icon: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 17,
                      ),
                    ),
                    IconButton(
                      onPressed: isBusy ? null : onManageAssignments,
                      tooltip: 'Asignaciones',
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.outline),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                      icon: const Icon(Icons.groups_2_outlined, size: 17),
                    ),
                    _DwStatusMenu(
                      currentStatus: discussion.status,
                      isBusy: isBusy,
                      onSelect: onChangeStatus,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _relativeActivity(Discussion item) {
    final source = item.updatedAt ?? item.createdAt;
    if (source == null) {
      return '-';
    }

    final now = DateTime.now();
    final diff = now.difference(source);
    if (diff.inMinutes < 1) {
      return 'ahora';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} h';
    }
    if (diff.inDays == 1) {
      return 'ayer';
    }
    return '${diff.inDays} d';
  }
}

class _DwTypeChip extends StatelessWidget {
  const _DwTypeChip({required this.type});

  final DiscussionType type;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final (label, accent) = switch (type) {
      DiscussionType.error => ('ERROR', semantic.discussionError),
      DiscussionType.idea => ('IDEA', semantic.discussionIdea),
      DiscussionType.improvement => ('MEJORA', semantic.discussionImprovement),
      DiscussionType.question => ('CONSULTA', semantic.discussionQuestion),
      DiscussionType.unknown => ('OTRO', Theme.of(context).colorScheme.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: accent),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DwUnreadIndicator extends StatelessWidget {
  const _DwUnreadIndicator({required this.isUnread});

  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    if (!isUnread) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: context.semanticColors.unread,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DwCreatorMeta extends StatelessWidget {
  const _DwCreatorMeta({required this.creator});

  final DiscussionCreator? creator;

  @override
  Widget build(BuildContext context) {
    final name = _displayName(creator);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Creado por:',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: _DwPersonPill(
              name: name,
              borderColor: Theme.of(context).colorScheme.outline,
              backgroundColor: AppColors.surfaceElevated,
              avatarBackground: AppColors.surface,
              avatarTextColor: AppColors.textSecondary,
              textColor: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  static String _displayName(DiscussionCreator? creator) {
    final fullName = creator?.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }

    final email = creator?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    final id = creator?.id.trim();
    if (id != null && id.isNotEmpty) {
      return id;
    }

    return 'Sin creador';
  }

}

class _DwPersonPill extends StatelessWidget {
  const _DwPersonPill({
    required this.name,
    required this.borderColor,
    required this.backgroundColor,
    required this.avatarBackground,
    required this.avatarTextColor,
    required this.textColor,
  });

  final String name;
  final Color borderColor;
  final Color backgroundColor;
  final Color avatarBackground;
  final Color avatarTextColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        color: backgroundColor,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: avatarBackground,
            child: Text(
              _DwAssigneeChips._initials(name),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: avatarTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DwContextChips extends StatelessWidget {
  const _DwContextChips({required this.discussion});

  final Discussion discussion;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[];
    for (final app in discussion.applications) {
      final name = app.name.trim();
      if (name.isNotEmpty && !labels.contains(name)) {
        labels.add(name);
      }
    }
    for (final indicator in discussion.indicators) {
      final name = indicator.name.trim();
      if (name.isNotEmpty && !labels.contains(name)) {
        labels.add(name);
      }
    }

    if (labels.isEmpty) {
      return Text(
        'Sin aplicacion o indicador',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    const visibleCount = 3;
    final visible = labels.take(visibleCount).toList(growable: false);
    final overflow = labels.length - visible.length;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final label in visible)
          Chip(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            label: Text(label, overflow: TextOverflow.ellipsis),
          ),
        if (overflow > 0)
          Chip(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            label: Text('+$overflow'),
          ),
      ],
    );
  }
}

class _DwAssigneeChips extends StatelessWidget {
  const _DwAssigneeChips({required this.assignees});

  final List<DiscussionAssignedDeveloper> assignees;

  @override
  Widget build(BuildContext context) {
    if (assignees.isEmpty) {
      return Text('Sin asignar', style: Theme.of(context).textTheme.labelSmall);
    }

    const visibleCount = 3;
    final visible = assignees.take(visibleCount).toList(growable: false);
    final overflow = assignees.length - visible.length;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final assignee in visible)
          Tooltip(
            message: assignee.fullName,
            child: _DwPersonPill(
              name: assignee.fullName,
              borderColor: Theme.of(context).colorScheme.outline,
              backgroundColor: AppColors.surfaceElevated,
              avatarBackground: AppColors.surface,
              avatarTextColor: AppColors.textSecondary,
              textColor: AppColors.textPrimary,
            ),
          ),
        if (overflow > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Text(
              '+$overflow',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
      ],
    );
  }

  static String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }
}

class _DwStatusMenu extends StatelessWidget {
  const _DwStatusMenu({
    required this.currentStatus,
    required this.isBusy,
    required this.onSelect,
  });

  final DiscussionRecordStatus currentStatus;
  final bool isBusy;
  final void Function(DiscussionRecordStatus status) onSelect;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DiscussionRecordStatus>(
      enabled: !isBusy,
      tooltip: 'Cambiar estado',
      itemBuilder: (context) {
        return DiscussionRecordStatus.values
            .where((status) => status != DiscussionRecordStatus.unknown)
            .map(
              (status) => PopupMenuItem<DiscussionRecordStatus>(
                value: status,
                child: Row(
                  children: [
                    Icon(
                      status == currentStatus
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(_statusLabel(status)),
                  ],
                ),
              ),
            )
            .toList(growable: false);
      },
      onSelected: (status) {
        if (status == currentStatus) {
          return;
        }
        onSelect(status);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alt_route_rounded, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _statusLabel(currentStatus),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(DiscussionRecordStatus status) {
    switch (status) {
      case DiscussionRecordStatus.newDiscussion:
        return 'Entrada';
      case DiscussionRecordStatus.review:
        return 'Revisión';
      case DiscussionRecordStatus.inProgress:
        return 'Trabajando';
      case DiscussionRecordStatus.resolved:
        return 'Resuelto';
      case DiscussionRecordStatus.unknown:
        return 'Desconocido';
    }
  }
}
