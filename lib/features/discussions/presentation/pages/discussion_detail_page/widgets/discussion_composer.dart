import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../discussion_messages/presentation/bloc/discussion_message_bloc.dart';
import '../../../../../discussion_messages/presentation/bloc/discussion_message_state.dart';
import '../../../bloc/discussion_bloc.dart';
import '../../../bloc/discussion_state.dart';
import '../discussion_detail_helpers.dart';

class DiscussionComposer extends StatelessWidget {
  const DiscussionComposer({
    required this.discussionId,
    required this.controller,
    required this.pendingAttachmentUpload,
    required this.onTextChanged,
    required this.onOpenAttachmentOptions,
    required this.onSend,
    super.key,
  });

  final String discussionId;
  final TextEditingController controller;
  final bool pendingAttachmentUpload;
  final VoidCallback onTextChanged;
  final VoidCallback onOpenAttachmentOptions;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscussionBloc, DiscussionState>(
      builder: (context, discussionState) {
        final hasDiscussion =
            resolveDiscussion(discussionState, discussionId) != null;

        return BlocBuilder<DiscussionMessageBloc, DiscussionMessageState>(
          builder: (context, messageState) {
            final canSendText = controller.text.trim().isNotEmpty;
            final blockedByState =
                !hasDiscussion ||
                messageState.isSending ||
                (messageState.status == DiscussionMessageStatus.loading &&
                    messageState.messages.isEmpty);

            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pendingAttachmentUpload && messageState.isSending)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 42,
                          width: 42,
                          child: OutlinedButton(
                            onPressed: blockedByState
                                ? null
                                : onOpenAttachmentOptions,
                            child: const Icon(Icons.add_rounded),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.send,
                            onChanged: (_) => onTextChanged(),
                            onSubmitted: (_) {
                              if (!blockedByState && canSendText) {
                                onSend();
                              }
                            },
                            decoration: const InputDecoration(
                              hintText: 'Escribir un mensaje...',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: blockedByState || !canSendText
                                ? null
                                : onSend,
                            icon: messageState.isSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: const Text('Enviar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
