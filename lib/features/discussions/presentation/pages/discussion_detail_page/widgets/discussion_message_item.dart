import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../discussion_messages/domain/entities/discussion_message.dart';
import '../discussion_detail_helpers.dart';
import 'discussion_message_actions_menu.dart';
import 'discussion_message_body.dart';
import 'discussion_message_inline_editor.dart';

const double _messageActionSlotWidth = 28;

class DiscussionMessageItem extends StatelessWidget {
  const DiscussionMessageItem({
    required this.message,
    required this.isGrouped,
    required this.canEdit,
    required this.canDelete,
    required this.isUpdating,
    required this.isDeleting,
    required this.isHovered,
    required this.isEditing,
    required this.editingController,
    required this.isSubmittingEdit,
    required this.onHoverChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.onOpenAttachment,
    super.key,
  });

  final DiscussionMessage message;
  final bool isGrouped;
  final bool canEdit;
  final bool canDelete;
  final bool isUpdating;
  final bool isDeleting;
  final bool isHovered;
  final bool isEditing;
  final TextEditingController? editingController;
  final bool isSubmittingEdit;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaveEdit;
  final DiscussionAttachmentOpener onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final showAvatar = !isGrouped;
    final showHeader = !isGrouped;
    final hasActions = canEdit || canDelete;

    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: EdgeInsets.only(top: showHeader ? AppSpacing.sm : 2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          color: isHovered && kIsWeb
              ? Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.34)
              : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              child: showAvatar
                  ? CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(
                        nameInitials(message.author.displayName),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader)
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            message.author.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          formatShortDateTime(message.createdAt),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const Spacer(),
                        _buildActionSlot(hasActions: hasActions),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 120),
                          opacity: isHovered && kIsWeb ? 1 : 0,
                          child: Text(
                            formatShortDateTime(message.createdAt),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildActionSlot(hasActions: hasActions),
                      ],
                    ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: isEditing && editingController != null
                        ? DiscussionMessageInlineEditor(
                            controller: editingController!,
                            isSubmitting: isSubmittingEdit,
                            onCancel: onCancelEdit,
                            onSave: onSaveEdit,
                          )
                        : DiscussionMessageBody(
                            message: message,
                            onOpenAttachment: onOpenAttachment,
                          ),
                  ),
                  if (isUpdating || isDeleting) ...[
                    const SizedBox(height: AppSpacing.xs),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSlot({required bool hasActions}) {
    if (!hasActions || isEditing) {
      return const SizedBox(width: _messageActionSlotWidth);
    }

    return SizedBox(
      width: _messageActionSlotWidth,
      child: Align(
        alignment: Alignment.centerRight,
        child: DiscussionMessageActionsMenu(
          canEdit: canEdit,
          canDelete: canDelete,
          isHovered: isHovered,
          isDeleting: isDeleting,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }
}
