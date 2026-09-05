import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../discussion_messages/domain/entities/discussion_message.dart';
import '../../../../../discussion_messages/presentation/bloc/discussion_message_state.dart';
import '../discussion_detail_helpers.dart';
import 'discussion_message_body.dart';
import 'discussion_message_item.dart';

/// Notifica el hover sobre un mensaje concreto de la conversacion.
typedef DiscussionMessageHoverChanged = void Function(
  String messageId,
  bool hovering,
);

class DiscussionConversationList extends StatelessWidget {
  const DiscussionConversationList({
    required this.messageState,
    required this.currentUserId,
    required this.scrollController,
    required this.hoveredMessageId,
    required this.editingMessageId,
    required this.editingController,
    required this.isSubmittingEdit,
    required this.onMessageHoverChanged,
    required this.onLoadMore,
    required this.onEditMessage,
    required this.onDeleteMessage,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.onOpenAttachment,
    super.key,
  });

  final DiscussionMessageState messageState;
  final String? currentUserId;
  final ScrollController scrollController;
  final String? hoveredMessageId;
  final String? editingMessageId;
  final TextEditingController? editingController;
  final bool isSubmittingEdit;
  final DiscussionMessageHoverChanged onMessageHoverChanged;
  final VoidCallback onLoadMore;
  final ValueChanged<DiscussionMessage> onEditMessage;
  final ValueChanged<DiscussionMessage> onDeleteMessage;
  final VoidCallback onCancelEdit;
  final ValueChanged<DiscussionMessage> onSaveEdit;
  final DiscussionAttachmentOpener onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    if (messageState.status == DiscussionMessageStatus.loading &&
        messageState.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final messages = messageState.messages;
    if (messages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'No hay mensajes en esta discussion todavia.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      itemCount: messages.length + (messageState.page.hasNext ? 1 : 0),
      itemBuilder: (context, index) {
        if (messageState.page.hasNext && index == messages.length) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Align(
              alignment: Alignment.center,
              child: OutlinedButton(
                onPressed: messageState.isLoadingMore ? null : onLoadMore,
                child: Text(
                  messageState.isLoadingMore ? 'Cargando...' : 'Cargar más',
                ),
              ),
            ),
          );
        }

        final message = messages[index];
        final previous = index > 0 ? messages[index - 1] : null;
        final isOwnMessage =
            currentUserId != null && message.author.id == currentUserId;

        return DiscussionMessageItem(
          message: message,
          isGrouped: isConsecutiveMessage(previous, message),
          canEdit: isOwnMessage && message.type == DiscussionMessageType.text,
          canDelete: isOwnMessage,
          isUpdating: messageState.isUpdating &&
              messageState.updatingMessageId == message.id,
          isDeleting: messageState.deletingMessageId == message.id,
          isHovered: hoveredMessageId == message.id,
          isEditing: editingMessageId == message.id,
          editingController: editingController,
          isSubmittingEdit: isSubmittingEdit,
          onHoverChanged: (hovering) =>
              onMessageHoverChanged(message.id, hovering),
          onEdit: () => onEditMessage(message),
          onDelete: () => onDeleteMessage(message),
          onCancelEdit: onCancelEdit,
          onSaveEdit: () => onSaveEdit(message),
          onOpenAttachment: onOpenAttachment,
        );
      },
    );
  }
}
