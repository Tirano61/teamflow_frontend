import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/network_config.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../applications/domain/entities/application.dart';
import '../../../applications/presentation/bloc/application_bloc.dart';
import '../../../applications/presentation/bloc/application_event.dart';
import '../../../applications/presentation/bloc/application_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../discussion_messages/domain/entities/discussion_message.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_bloc.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_event.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_state.dart';
import '../../../indicators/domain/entities/indicator.dart';
import '../../../indicators/presentation/bloc/indicator_bloc.dart';
import '../../../indicators/presentation/bloc/indicator_event.dart';
import '../../../indicators/presentation/bloc/indicator_state.dart';
import '../../../notifications/presentation/bloc/notification_bloc.dart';
import '../../../notifications/presentation/bloc/notification_event.dart';
import '../../../notifications/presentation/bloc/notification_state.dart';
import '../../../tags/presentation/bloc/tag_bloc.dart';
import '../../../tags/presentation/bloc/tag_event.dart';
import '../../../tags/presentation/bloc/tag_state.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_developer.dart';
import '../bloc/discussion_bloc.dart';
import '../bloc/discussion_event.dart';
import '../bloc/discussion_state.dart';
import '../widgets/messages/discussion_audio_message.dart';
import '../widgets/messages/discussion_file_message.dart';
import '../widgets/messages/discussion_image_message.dart';
import '../widgets/messages/discussion_text_message.dart';
import '../widgets/messages/discussion_video_message.dart';

class DiscussionDetailPage extends StatefulWidget {
  const DiscussionDetailPage({
    required this.discussionId,
    this.embedded = false,
    this.onClose,
    super.key,
  });

  final String discussionId;
  final bool embedded;
  final VoidCallback? onClose;

  @override
  State<DiscussionDetailPage> createState() => _DiscussionDetailPageState();
}

class _DiscussionDetailPageState extends State<DiscussionDetailPage>
    with RouteAware {
  static const double _messageActionSlotWidth = 28;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _contentScrollController = ScrollController();

  bool _pendingComposerClear = false;
  bool _pendingAttachmentUpload = false;
  String? _markAsReadRequestedForDiscussionId;
  bool _routeObserverSubscribed = false;
  int _lastKnownMessageCount = 0;
  NotificationBloc? _notificationBloc;
  String? _hoveredMessageId;
  _AttachmentOption? _lastAttachmentOption;
  bool _isCopyableErrorDialogOpen = false;

  // Inline editing state
  String? _editingMessageId;
  TextEditingController? _editingController;
  bool _submittingEdit = false;

  static const int _maxWebVideoUploadBytes =
      120 * 1024 * 1024; // 120 MB para video en web.

  @override
  void initState() {
    super.initState();
    _lastKnownMessageCount = 0;
    _setActiveDiscussionId(widget.discussionId);
    _loadCatalogs();
    _loadDiscussion();
    _loadMessages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notificationBloc ??= context.read<NotificationBloc>();

    if (_routeObserverSubscribed) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route != null) {
      AppRouter.routeObserver.subscribe(this, route);
      _routeObserverSubscribed = true;
    }
  }

  @override
  void didUpdateWidget(covariant DiscussionDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.discussionId == widget.discussionId) {
      return;
    }

    _setActiveDiscussionId(widget.discussionId);
    _markAsReadRequestedForDiscussionId = null;
    _lastKnownMessageCount = 0;
    _loadDiscussion();
    _loadMessages();
  }

  @override
  void dispose() {
    if (_routeObserverSubscribed) {
      AppRouter.routeObserver.unsubscribe(this);
      _routeObserverSubscribed = false;
    }
    _clearActiveDiscussionId();
    _messageController.dispose();
    _contentScrollController.dispose();
    _editingController?.dispose();
    super.dispose();
  }

  @override
  void didPush() {
    _setActiveDiscussionId(widget.discussionId);
  }

  @override
  void didPopNext() {
    _setActiveDiscussionId(widget.discussionId);
  }

  @override
  void didPushNext() {
    _clearActiveDiscussionId();
  }

  @override
  void didPop() {
    _clearActiveDiscussionId();
  }

  @override
  Widget build(BuildContext context) {
    final content = MultiBlocListener(
      listeners: [
        BlocListener<DiscussionBloc, DiscussionState>(
          listener: _onDiscussionStateChanged,
        ),
        BlocListener<DiscussionMessageBloc, DiscussionMessageState>(
          listener: _onDiscussionMessageStateChanged,
        ),
        BlocListener<NotificationBloc, NotificationState>(
          listenWhen: (previous, current) =>
              previous.refreshRequestVersion != current.refreshRequestVersion,
          listener: _onNotificationRefreshRequested,
        ),
        BlocListener<NotificationBloc, NotificationState>(
          listenWhen: (previous, current) =>
              previous.syncVersion != current.syncVersion,
          listener: _onNotificationSilentSyncRequested,
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: BlocBuilder<DiscussionBloc, DiscussionState>(
              builder: (context, discussionState) {
                final discussion = _resolveDiscussion(discussionState);

                return BlocBuilder<DiscussionMessageBloc, DiscussionMessageState>(
                  builder: (context, messageState) {
                    if (discussionState.status == DiscussionStatus.loading &&
                        discussion == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (discussion == null) {
                      return _buildMissingDiscussionState();
                    }

                    return _buildDetailContent(
                      discussion: discussion,
                      messageState: messageState,
                    );
                  },
                );
              },
            ),
          ),
          _buildComposer(),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de discussion'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: content,
    );
  }

  Widget _buildMissingDiscussionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se encontraron datos para la discussion.'),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () {
                _loadDiscussion();
                _loadMessages();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent({
    required Discussion discussion,
    required DiscussionMessageState messageState,
  }) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState.session?.user;
    final currentUserId = currentUser?.id;
    final isDeveloper = currentUser?.isDeveloper ?? false;

    return Column(
      children: [
        _buildDiscussionHeader(
          discussion: discussion,
          messageState: messageState,
          isDeveloper: isDeveloper,
        ),
        Expanded(
          child: Stack(
            children: [
              _buildConversationList(
                discussion: discussion,
                messageState: messageState,
                currentUserId: currentUserId,
                isDeveloper: isDeveloper,
              ),
              if (messageState.isRefreshing)
                const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiscussionHeader({
    required Discussion discussion,
    required DiscussionMessageState messageState,
    required bool isDeveloper,
  }) {
    final statusBusy = _isStatusBusy(discussion.id);
    final assigneesBusy = _isAssignmentsBusy(discussion.id);
    final compact = _isCompactLayout(context);

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
              _buildTypeChip(discussion.type),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Canal:',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _buildStatusControl(
                    discussion: discussion,
                    isDeveloper: isDeveloper,
                    disabled: statusBusy || messageState.isSending,
                  ),
                ],
              ),
              Text(
                _formatShortDateTime(discussion.updatedAt ?? discussion.createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (widget.embedded) ...[
                IconButton(
                  tooltip: 'Cerrar panel',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: widget.onClose,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _normalizedTitle(discussion.title),
            maxLines: compact ? 2 : 2,
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
              ..._buildContextChips(
                label: 'Aplicacion',
                values: _extractApplicationLabels(discussion),
                emptyLabel: 'Sin aplicación',
                onTap: isDeveloper
                    ? () => _openApplicationSelector(discussion)
                    : null,
              ),
              ..._buildContextChips(
                label: 'Indicador',
                values: _extractIndicatorLabels(discussion),
                emptyLabel: 'Sin indicador',
                onTap: isDeveloper
                    ? () => _openIndicatorSelector(discussion)
                    : null,
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
                    _buildAssigneeSection(
                      discussion: discussion,
                      isDeveloper: isDeveloper,
                      disabled: assigneesBusy,
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
                        _buildPersonPill(
                          name: _creatorDisplayName(discussion.createdBy),
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
              if (messageState.isSending || statusBusy || assigneesBusy)
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

  Widget _buildConversationList({
    required Discussion discussion,
    required DiscussionMessageState messageState,
    required String? currentUserId,
    required bool isDeveloper,
  }) {
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
      controller: _contentScrollController,
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
                onPressed: messageState.isLoadingMore
                    ? null
                    : () => _loadMoreMessages(messageState),
                child: Text(
                  messageState.isLoadingMore
                      ? 'Cargando...'
                      : 'Cargar más',
                ),
              ),
            ),
          );
        }

        final message = messages[index];
        final previous = index > 0 ? messages[index - 1] : null;
        final isGrouped = _isConsecutiveMessage(previous, message);
        final isOwnMessage =
            currentUserId != null && message.author.id == currentUserId;
        final canEditMessage =
            isOwnMessage && message.type == DiscussionMessageType.text;
        final canDeleteMessage = isOwnMessage;
        final isUpdatingThisMessage =
            messageState.isUpdating && messageState.updatingMessageId == message.id;
        final isDeletingThisMessage =
            messageState.deletingMessageId == message.id;

        return _buildMessageItem(
          message: message,
          isGrouped: isGrouped,
          canEditMessage: canEditMessage,
          canDeleteMessage: canDeleteMessage,
          isUpdatingThisMessage: isUpdatingThisMessage,
          isDeletingThisMessage: isDeletingThisMessage,
        );
      },
    );
  }

  Widget _buildMessageItem({
    required DiscussionMessage message,
    required bool isGrouped,
    required bool canEditMessage,
    required bool canDeleteMessage,
    required bool isUpdatingThisMessage,
    required bool isDeletingThisMessage,
  }) {
    final showAvatar = !isGrouped;
    final showHeader = !isGrouped;
    final isHovered = _hoveredMessageId == message.id;
    final isEditingThisMessage = _editingMessageId == message.id;
    final hasActions = canEditMessage || canDeleteMessage;

    return MouseRegion(
      onEnter: (_) {
        if (!kIsWeb) {
          return;
        }
        setState(() {
          _hoveredMessageId = message.id;
        });
      },
      onExit: (_) {
        if (!kIsWeb) {
          return;
        }
        setState(() {
          if (_hoveredMessageId == message.id) {
            _hoveredMessageId = null;
          }
        });
      },
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
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(
                        _initials(message.author.displayName),
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _formatShortDateTime(message.createdAt),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const Spacer(),
                        _buildMessageActionSlot(
                          hasActions: hasActions,
                          isEditingThisMessage: isEditingThisMessage,
                          menu: _buildMessageActionsMenu(
                            message: message,
                            canEdit: canEditMessage,
                            canDelete: canDeleteMessage,
                            isHovered: isHovered,
                            isDeletingThisMessage: isDeletingThisMessage,
                          ),
                        ),
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
                            _formatShortDateTime(message.createdAt),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildMessageActionSlot(
                          hasActions: hasActions,
                          isEditingThisMessage: isEditingThisMessage,
                          menu: _buildMessageActionsMenu(
                            message: message,
                            canEdit: canEditMessage,
                            canDelete: canDeleteMessage,
                            isHovered: isHovered,
                            isDeletingThisMessage: isDeletingThisMessage,
                          ),
                        ),
                      ],
                    ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: isEditingThisMessage
                        ? _buildInlineEditor(message)
                        : _buildMessageBody(message),
                  ),
                  if (isUpdatingThisMessage || isDeletingThisMessage) ...[
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

  Widget _buildMessageActionsMenu({
    required DiscussionMessage message,
    required bool canEdit,
    required bool canDelete,
    required bool isHovered,
    required bool isDeletingThisMessage,
  }) {
    // On web: only show menu icon when hovered; on mobile: always visible
    final visible = kIsWeb ? isHovered : true;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: visible ? 1.0 : 0.0,
      child: PopupMenuButton<_MessageAction>(
        iconSize: 16,
        padding: EdgeInsets.zero,
        tooltip: 'Acciones del mensaje',
        enabled: !isDeletingThisMessage,
        icon: Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        itemBuilder: (context) => [
          if (canEdit)
            PopupMenuItem<_MessageAction>(
              value: _MessageAction.edit,
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Editar'),
                ],
              ),
            ),
          if (canDelete)
            PopupMenuItem<_MessageAction>(
              value: _MessageAction.delete,
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Eliminar',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
        onSelected: (action) {
          switch (action) {
            case _MessageAction.edit:
              _startInlineEdit(message);
            case _MessageAction.delete:
              _confirmDeleteMessage(message);
          }
        },
      ),
    );
  }

  Widget _buildMessageActionSlot({
    required bool hasActions,
    required bool isEditingThisMessage,
    required Widget menu,
  }) {
    if (!hasActions || isEditingThisMessage) {
      return const SizedBox(width: _messageActionSlotWidth);
    }

    return SizedBox(
      width: _messageActionSlotWidth,
      child: Align(alignment: Alignment.centerRight, child: menu),
    );
  }

  Widget _buildInlineEditor(DiscussionMessage message) {
    final controller = _editingController;
    if (controller == null) {
      return _buildMessageBody(message);
    }

    final isSubmitting = _submittingEdit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 8,
          enabled: !isSubmitting,
          decoration: const InputDecoration(
            hintText: 'Editar mensaje...',
            isDense: true,
          ),
          onSubmitted: (_) => _saveInlineEdit(message),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: isSubmitting ? null : _cancelInlineEdit,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: AppSpacing.xs),
            FilledButton(
              onPressed: isSubmitting ? null : () => _saveInlineEdit(message),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageBody(DiscussionMessage message) {
    switch (message.type) {
      case DiscussionMessageType.text:
        return DiscussionTextMessage(content: message.content);
      case DiscussionMessageType.image:
        return DiscussionImageMessage(
          fileUrl: message.attachmentUrl,
          caption: message.content,
        );
      case DiscussionMessageType.audio:
        return DiscussionAudioMessage(
          fileUrl: message.attachmentUrl,
          caption: message.content,
          onOpenExternally: () => _openAttachmentUrl(message.attachmentUrl),
        );
      case DiscussionMessageType.video:
        return DiscussionVideoMessage(
          fileUrl: message.attachmentUrl,
          caption: message.content,
          onOpenExternally: () => _openAttachmentUrl(message.attachmentUrl),
        );
      case DiscussionMessageType.file:
      case DiscussionMessageType.unknown:
        return DiscussionFileMessage(
          message: message,
          onOpen: () =>
              _openAttachmentUrl(message.attachmentUrl, preferDownload: kIsWeb),
        );
    }
  }

  Widget _buildComposer() {
    return BlocBuilder<DiscussionBloc, DiscussionState>(
      builder: (context, discussionState) {
        final hasDiscussion = _resolveDiscussion(discussionState) != null;

        return BlocBuilder<DiscussionMessageBloc, DiscussionMessageState>(
          builder: (context, messageState) {
            final messageText = _messageController.text.trim();
            final canSendText = messageText.isNotEmpty;
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
                    top: BorderSide(color: Theme.of(context).colorScheme.outline),
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
                    if (_pendingAttachmentUpload && messageState.isSending)
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
                                : _openAttachmentOptions,
                            child: const Icon(Icons.add_rounded),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.send,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) {
                              if (!blockedByState && canSendText) {
                                _sendMessage();
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
                                : _sendMessage,
                            icon: messageState.isSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
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

  Widget _buildStatusControl({
    required Discussion discussion,
    required bool isDeveloper,
    required bool disabled,
  }) {
    final semantic = context.semanticColors;
    final accent = _statusAccent(discussion.status, semantic);
    final label = _statusLabel(discussion.status);

    if (!isDeveloper) {
      return _buildInfoChip(
        icon: Icons.flag_rounded,
        text: label,
        accent: accent,
      );
    }

    if (_isCompactLayout(context)) {
      return InkWell(
        onTap: disabled ? null : () => _openStatusBottomSheet(discussion),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: _buildInfoChip(
          icon: Icons.alt_route_rounded,
          text: label,
          accent: accent,
        ),
      );
    }

    return PopupMenuButton<DiscussionRecordStatus>(
      enabled: !disabled,
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
                      status == discussion.status
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
        if (status == discussion.status) {
          return;
        }
        _changeDiscussionStatus(discussion, status);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInfoChip(
            icon: Icons.alt_route_rounded,
            text: label,
            accent: accent,
          ),
        ],
      ),
    );
  }

  Future<void> _openStatusBottomSheet(Discussion discussion) async {
    final selected = await showModalBottomSheet<DiscussionRecordStatus>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text('Cambiar estado', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              for (final status in DiscussionRecordStatus.values.where(
                (status) => status != DiscussionRecordStatus.unknown,
              ))
                ListTile(
                  title: Text(_statusLabel(status)),
                  trailing: status == discussion.status
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, status),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null || selected == discussion.status) {
      return;
    }

    _changeDiscussionStatus(discussion, selected);
  }

  Widget _buildAssigneeSection({
    required Discussion discussion,
    required bool isDeveloper,
    required bool disabled,
  }) {
    return InkWell(
      onTap: isDeveloper && !disabled ? () => _openAssignmentsDialog(discussion) : null,
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
                children: _buildAssigneeChips(discussion.assignedDevelopers),
              ),
            ),
          if (isDeveloper) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(
              _isCompactLayout(context)
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.edit_outlined,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildAssigneeChips(List<DiscussionAssignedDeveloper> assignees) {
    const visibleCount = 4;
    final visible = assignees.take(visibleCount).toList(growable: false);
    final overflow = assignees.length - visible.length;

    final chips = <Widget>[];
    for (final assignee in visible) {
      chips.add(
        Tooltip(
          message: assignee.fullName,
          child: _buildPersonPill(
            name: assignee.fullName,
            borderColor: Theme.of(context).colorScheme.outline,
            avatarBackground: Theme.of(context).colorScheme.surfaceContainerHighest,
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
          child: Text('+$overflow', style: Theme.of(context).textTheme.labelSmall),
        ),
      );
    }

    return chips;
  }

  Widget _buildPersonPill({
    required String name,
    required Color borderColor,
    required Color? avatarBackground,
    required Color? avatarTextColor,
    required Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: avatarBackground,
            child: Text(
              _initials(name),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: avatarTextColor,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(DiscussionType type) {
    final semantic = context.semanticColors;
    final (label, accent) = switch (type) {
      DiscussionType.error => ('ERROR', semantic.discussionError),
      DiscussionType.idea => ('IDEA', semantic.discussionIdea),
      DiscussionType.improvement => ('MEJORA', semantic.discussionImprovement),
      DiscussionType.question => ('CONSULTA', semantic.discussionQuestion),
      DiscussionType.unknown => ('OTRO', Theme.of(context).colorScheme.outline),
    };

    return _buildInfoChip(
      icon: Icons.sell_outlined,
      text: label,
      accent: accent,
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContextChips({
    required String label,
    required List<String> values,
    String? emptyLabel,
    VoidCallback? onTap,
  }) {
    final canTap = onTap != null;

    Widget wrapChip(Widget chip) {
      if (!canTap) {
        return chip;
      }
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: chip,
      );
    }

    if (values.isEmpty) {
      return [
        wrapChip(
          Chip(
            visualDensity: VisualDensity.compact,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emptyLabel ?? '$label: Sin asignar'),
                if (canTap) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.add_rounded, size: 14),
                ],
              ],
            ),
          ),
        ),
      ];
    }

    const visibleCount = 3;
    final visible = values.take(visibleCount).toList(growable: false);
    final overflow = values.length - visible.length;

    final result = <Widget>[];
    for (final value in visible) {
      result.add(
        wrapChip(
          Chip(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '$label: $value',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canTap) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_outlined, size: 13),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (overflow > 0) {
      result.add(
        wrapChip(
          Chip(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            label: Text('+$overflow'),
          ),
        ),
      );
    }

    return result;
  }

  void _loadDiscussion() {
    context.read<DiscussionBloc>().add(LoadDiscussionEvent(widget.discussionId));
  }

  void _setActiveDiscussionId(String discussionId) {
    _notificationBloc?.add(
      NotificationActiveDiscussionChangedEvent(discussionId: discussionId),
    );
  }

  void _clearActiveDiscussionId() {
    _notificationBloc?.add(
      const NotificationActiveDiscussionChangedEvent(discussionId: null),
    );
  }

  void _onNotificationRefreshRequested(
    BuildContext context,
    NotificationState state,
  ) {
    final refreshDiscussionId = state.refreshDiscussionId?.trim();
    if (refreshDiscussionId == null || refreshDiscussionId != widget.discussionId) {
      return;
    }

    _refreshDiscussionAndMessages();
  }

  void _onNotificationSilentSyncRequested(
    BuildContext context,
    NotificationState state,
  ) {
    final syncDiscussionId = state.syncDiscussionId?.trim();
    if (syncDiscussionId == null || syncDiscussionId != widget.discussionId) {
      return;
    }

    switch (state.syncType) {
      case NotificationSyncType.discussionAndMessages:
        _refreshDiscussionAndMessages();
        break;
      case NotificationSyncType.messagesOnly:
        _refreshMessagesOnly();
        break;
      case NotificationSyncType.contextOnly:
        _refreshDiscussionOnly();
        break;
      case NotificationSyncType.none:
        break;
    }
  }

  void _onDiscussionStateChanged(BuildContext context, DiscussionState state) {
    if (state.status == DiscussionStatus.error && state.errorMessage.isNotEmpty) {
      _showMessage(state.errorMessage);
    }

    final discussion = _resolveDiscussion(state);
    if (discussion == null || !discussion.isUnread) {
      return;
    }

    if (_markAsReadRequestedForDiscussionId == widget.discussionId) {
      return;
    }

    _markAsReadRequestedForDiscussionId = widget.discussionId;
    context.read<DiscussionBloc>().add(MarkDiscussionAsReadEvent(widget.discussionId));
  }

  void _loadMessages({int page = 1}) {
    context.read<DiscussionMessageBloc>().add(
      LoadDiscussionMessagesEvent(
        discussionId: widget.discussionId,
        page: page,
        limit: 50,
      ),
    );
  }

  void _refreshDiscussionAndMessages() {
    _loadDiscussion();
    debugPrint(
      '[DISCUSSION] refresh dispatched - ${_timestampNow()} - discussionId=${widget.discussionId}',
    );
    context.read<DiscussionMessageBloc>().add(
      RefreshDiscussionMessagesEvent(
        discussionId: widget.discussionId,
        limit: 50,
      ),
    );
  }

  void _refreshMessagesOnly() {
    debugPrint(
      '[DISCUSSION] messages refresh dispatched - ${_timestampNow()} - discussionId=${widget.discussionId}',
    );
    context.read<DiscussionMessageBloc>().add(
      RefreshDiscussionMessagesEvent(
        discussionId: widget.discussionId,
        limit: 50,
      ),
    );
  }

  void _refreshDiscussionOnly() {
    debugPrint(
      '[DISCUSSION] context refresh dispatched - ${_timestampNow()} - discussionId=${widget.discussionId}',
    );
    _loadDiscussion();
  }

  void _loadMoreMessages(DiscussionMessageState state) {
    if (state.isLoadingMore || !state.page.hasNext) {
      return;
    }

    context.read<DiscussionMessageBloc>().add(
      LoadMoreDiscussionMessagesEvent(
        discussionId: widget.discussionId,
        limit: state.page.limit,
      ),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      return;
    }

    _pendingComposerClear = true;
    context.read<DiscussionMessageBloc>().add(
      CreateDiscussionMessageEvent(
        discussionId: widget.discussionId,
        type: DiscussionMessageType.text,
        content: content,
      ),
    );
  }

  Future<void> _openAttachmentOptions() async {
    final compactLayout = _isCompactLayout(context);
    final selectedOption = compactLayout
        ? await _showAttachmentOptionsBottomSheet()
        : await _showAttachmentOptionsMenu();

    if (!mounted || selectedOption == null) {
      return;
    }

    await _pickAndSendAttachment(selectedOption);
  }

  Future<_AttachmentOption?> _showAttachmentOptionsBottomSheet() {
    return showModalBottomSheet<_AttachmentOption>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text('Adjuntar', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              ..._AttachmentOption.values.map(
                (option) => ListTile(
                  leading: Icon(option.icon),
                  title: Text(option.label),
                  onTap: () => Navigator.pop(sheetContext, option),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  Future<_AttachmentOption?> _showAttachmentOptionsMenu() async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      return null;
    }

    final position = RelativeRect.fromLTRB(
      box.size.width - 220,
      box.size.height - 140,
      12,
      12,
    );

    return showMenu<_AttachmentOption>(
      context: context,
      position: position,
      items: [
        for (final option in _AttachmentOption.values)
          PopupMenuItem<_AttachmentOption>(
            value: option,
            child: Row(
              children: [
                Icon(option.icon, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(option.label),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _pickAndSendAttachment(_AttachmentOption option) async {
    try {
      final selection = await FilePicker.platform.pickFiles(
        type: option.filePickerType,
        allowMultiple: false,
        withData: true,
        allowedExtensions: option.allowedExtensions,
      );

      if (!mounted || selection == null || selection.files.isEmpty) {
        return;
      }

      final picked = selection.files.first;
      final bytes = picked.bytes;
      final rawName = picked.name.trim();
      final originalFileName = rawName.isNotEmpty ? rawName : 'attachment';
      final optionalContent = _messageController.text.trim();

      if (bytes == null || bytes.isEmpty) {
        _showMessage('No se pudo leer el archivo seleccionado.');
        return;
      }

      var uploadFileName = originalFileName;
      var uploadBytes = bytes;

      if (option == _AttachmentOption.image) {
        final optimized = _optimizeImageForUpload(
          originalBytes: bytes,
          originalFileName: originalFileName,
        );
        uploadFileName = optimized.fileName;
        uploadBytes = optimized.bytes;

        if (optimized.wasOptimized && mounted) {
          final originalKb = (bytes.length / 1024).round();
          final optimizedKb = (uploadBytes.length / 1024).round();
          _showMessage('Imagen optimizada: $originalKb KB -> $optimizedKb KB');
        }
      }

      if (kIsWeb &&
          option == _AttachmentOption.video &&
          uploadBytes.length > _maxWebVideoUploadBytes) {
        final sizeMb = (uploadBytes.length / (1024 * 1024)).toStringAsFixed(1);
        _showMessage(
          'Video demasiado grande para carga web directa ($sizeMb MB). '
          'Prueba con un video mas liviano o comprime el archivo.',
        );
        return;
      }

      _pendingComposerClear = true;
      _pendingAttachmentUpload = true;
      _lastAttachmentOption = option;
      context.read<DiscussionMessageBloc>().add(
        CreateDiscussionAttachmentMessageEvent(
          discussionId: widget.discussionId,
          type: option.type,
          fileName: uploadFileName,
          fileBytes: uploadBytes,
          content: optionalContent.isEmpty ? null : optionalContent,
        ),
      );
    } on PlatformException {
      if (mounted) {
        _showMessage('No se pudo abrir el selector de archivos.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Ocurrio un error al adjuntar el archivo.');
      }
    }
  }

  void _startInlineEdit(DiscussionMessage message) {
    if (message.type != DiscussionMessageType.text) {
      return;
    }
    _editingController?.dispose();
    setState(() {
      _editingMessageId = message.id;
      _editingController = TextEditingController(text: message.content);
    });
  }

  void _cancelInlineEdit() {
    _editingController?.dispose();
    setState(() {
      _editingMessageId = null;
      _editingController = null;
    });
  }

  void _saveInlineEdit(DiscussionMessage message) {
    final content = _editingController?.text.trim() ?? '';
    if (content.isEmpty) {
      return;
    }
    _submittingEdit = true;
    context.read<DiscussionMessageBloc>().add(
      UpdateDiscussionMessageEvent(
        discussionId: widget.discussionId,
        messageId: message.id,
        content: content,
      ),
    );
  }

  Future<void> _confirmDeleteMessage(DiscussionMessage message) async {
    final isAttachment = message.type != DiscussionMessageType.text;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isAttachment ? '¿Eliminar archivo?' : '¿Eliminar mensaje?'),
          content: Text(
            isAttachment
                ? '¿Eliminar este archivo de la conversación?\nEl archivo también será eliminado.'
                : '¿Eliminar este mensaje?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    context.read<DiscussionMessageBloc>().add(
      DeleteDiscussionMessageEvent(
        discussionId: widget.discussionId,
        messageId: message.id,
      ),
    );
  }

  void _onDiscussionMessageStateChanged(
    BuildContext context,
    DiscussionMessageState state,
  ) {
    final hasNewMessages = state.messages.length > _lastKnownMessageCount;
    final shouldAutoScrollForIncoming = hasNewMessages && _isNearBottomBeforeUpdate();
    _lastKnownMessageCount = state.messages.length;

    if (state.status == DiscussionMessageStatus.error &&
        state.errorMessage.isNotEmpty) {
      _pendingAttachmentUpload = false;
      _pendingComposerClear = false;

      // On edit error: keep editing state so user can retry
      if (_submittingEdit) {
        _submittingEdit = false;
        _showMessage(state.errorMessage);
        return;
      }

      final isWebVideoUploadFailure =
          kIsWeb &&
          _lastAttachmentOption == _AttachmentOption.video &&
          state.errorMessage.toLowerCase().contains('failed to fetch');

      if (isWebVideoUploadFailure) {
        final fullMessage =
          '${state.errorMessage}\n\n'
          'Tip tecnico: este error suele aparecer cuando el backend bloquea '
          'CORS en POST/OPTIONS de /messages/files o cuando el gateway rechaza '
          'el tamaño del video sin devolver cabeceras CORS.\n\n'
          '${_buildWebUploadDiagnosticBlock()}';

        _showCopyableErrorDialog(fullMessage);
      } else {
        if (kIsWeb && _pendingAttachmentUpload) {
          _showCopyableErrorDialog(
            '${state.errorMessage}\n\n${_buildWebUploadDiagnosticBlock()}',
          );
        } else {
          _showMessage(state.errorMessage);
        }
      }
      _lastAttachmentOption = null;
      return;
    }

    // Clear inline edit on successful save
    if (_submittingEdit &&
        !state.isUpdating &&
        state.status == DiscussionMessageStatus.success) {
      _submittingEdit = false;
      if (mounted) {
        setState(() {
          _editingController?.dispose();
          _editingController = null;
          _editingMessageId = null;
        });
      }
    }

    if (_pendingComposerClear &&
        !state.isSending &&
        state.status == DiscussionMessageStatus.success) {
      _pendingAttachmentUpload = false;
      _pendingComposerClear = false;
      _lastAttachmentOption = null;
      _messageController.clear();
      _scheduleScrollToBottom();
      return;
    }

    if (shouldAutoScrollForIncoming && !state.isLoadingMore) {
      _scheduleScrollToBottom();
    }
  }

  bool _isNearBottomBeforeUpdate() {
    if (!_contentScrollController.hasClients) {
      return true;
    }

    final position = _contentScrollController.position;
    return (position.maxScrollExtent - position.pixels) <= 120;
  }

  bool _isConsecutiveMessage(DiscussionMessage? previous, DiscussionMessage current) {
    if (previous == null) {
      return false;
    }

    if (previous.author.id != current.author.id) {
      return false;
    }

    final previousCreatedAt = previous.createdAt;
    final currentCreatedAt = current.createdAt;
    if (previousCreatedAt == null || currentCreatedAt == null) {
      return true;
    }

    final diffMinutes = currentCreatedAt.difference(previousCreatedAt).inMinutes;
    return diffMinutes >= 0 && diffMinutes <= 7;
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_contentScrollController.hasClients) {
        return;
      }

      _contentScrollController.animateTo(
        _contentScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openAttachmentUrl(
    String? rawUrl, {
    bool preferDownload = false,
  }) async {
    final normalizedUrl = rawUrl?.trim();
    if (normalizedUrl == null || normalizedUrl.isEmpty) {
      _showMessage('No se pudo abrir el archivo.');
      return;
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) {
      _showMessage('No se pudo abrir el archivo.');
      return;
    }

    final launchMode =
        kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;
    final launched = await launchUrl(
      uri,
      mode: launchMode,
      webOnlyWindowName: preferDownload ? '_blank' : null,
    );

    if (!launched) {
      _showMessage('No se pudo abrir el archivo.');
    }
  }

  Discussion? _resolveDiscussion(DiscussionState state) {
    final selected = state.selectedDiscussion;
    if (selected != null && selected.id == widget.discussionId) {
      return selected;
    }

    for (final discussion in state.discussions) {
      if (discussion.id == widget.discussionId) {
        return discussion;
      }
    }

    return null;
  }

  List<String> _extractApplicationLabels(Discussion discussion) {
    if (discussion.applications.isNotEmpty) {
      return discussion.applications
          .map((application) => application.name.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }

    final labelsById = {
      for (final item in context.read<ApplicationBloc>().state.applications)
        if ((item.id?.trim() ?? '').isNotEmpty) item.id!.trim(): item.name.trim(),
    };

    final labels = discussion.resolvedApplicationIds
        .map((id) => labelsById[id.trim()] ?? '')
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);

    return labels;
  }

  List<String> _extractIndicatorLabels(Discussion discussion) {
    if (discussion.indicators.isNotEmpty) {
      return discussion.indicators
          .map((indicator) => indicator.name.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }

    final labelsById = {
      for (final item in context.read<IndicatorBloc>().state.indicators)
        if ((item.id?.trim() ?? '').isNotEmpty) item.id!.trim(): item.name.trim(),
    };

    final labels = discussion.resolvedIndicatorIds
        .map((id) => labelsById[id.trim()] ?? '')
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);

    return labels;
  }

  void _loadCatalogs() {
    final appBloc = context.read<ApplicationBloc>();
    if (appBloc.state.applications.isEmpty &&
        appBloc.state.status != ApplicationStatus.loading) {
      appBloc.add(const LoadApplicationsEvent());
    }

    final indicatorBloc = context.read<IndicatorBloc>();
    if (indicatorBloc.state.indicators.isEmpty &&
        indicatorBloc.state.status != IndicatorStatus.loading) {
      indicatorBloc.add(const LoadIndicatorsEvent());
    }

    final tagBloc = context.read<TagBloc>();
    if (tagBloc.state.tags.isEmpty && tagBloc.state.status != TagStatus.loading) {
      tagBloc.add(const LoadTagsEvent());
    }
  }

  Future<void> _openApplicationSelector(Discussion discussion) async {
    final discussionId = discussion.id;
    if (discussionId == null || discussionId.isEmpty) {
      return;
    }

    final appBloc = context.read<ApplicationBloc>();
    if (appBloc.state.applications.isEmpty) {
      appBloc.add(const LoadApplicationsEvent());
    }

    final discussionBloc = context.read<DiscussionBloc>();
    final selectedIds = Set<String>.from(discussion.resolvedApplicationIds);
    final compact = _isCompactLayout(context);

    final savedIds = compact
        ? await _showCatalogSelectorSheet<Application>(
            title: 'Aplicaciones',
            bloc: appBloc,
            items: appBloc.state.applications,
            selectedIds: selectedIds,
            idOf: (app) => app.id ?? '',
            nameOf: (app) => app.name,
            isLoading: appBloc.state.status == ApplicationStatus.loading,
          )
        : await _showCatalogSelectorDialog<Application>(
            title: 'Aplicaciones',
            bloc: appBloc,
            items: appBloc.state.applications,
            selectedIds: selectedIds,
            idOf: (app) => app.id ?? '',
            nameOf: (app) => app.name,
            isLoading: appBloc.state.status == ApplicationStatus.loading,
          );

    if (!mounted || savedIds == null) {
      return;
    }

    discussionBloc.add(
      UpdateDiscussionEvent(
        discussion.copyWith(
          applicationIds: savedIds.toList(),
          applications: const [],
        ),
      ),
    );
  }

  Future<void> _openIndicatorSelector(Discussion discussion) async {
    final discussionId = discussion.id;
    if (discussionId == null || discussionId.isEmpty) {
      return;
    }

    final indicatorBloc = context.read<IndicatorBloc>();
    if (indicatorBloc.state.indicators.isEmpty) {
      indicatorBloc.add(const LoadIndicatorsEvent());
    }

    final discussionBloc = context.read<DiscussionBloc>();
    final selectedIds = Set<String>.from(discussion.resolvedIndicatorIds);
    final compact = _isCompactLayout(context);

    final savedIds = compact
        ? await _showCatalogSelectorSheet<Indicator>(
            title: 'Indicadores',
            bloc: indicatorBloc,
            items: indicatorBloc.state.indicators,
            selectedIds: selectedIds,
            idOf: (ind) => ind.id ?? '',
            nameOf: (ind) => ind.name,
            isLoading: indicatorBloc.state.status == IndicatorStatus.loading,
          )
        : await _showCatalogSelectorDialog<Indicator>(
            title: 'Indicadores',
            bloc: indicatorBloc,
            items: indicatorBloc.state.indicators,
            selectedIds: selectedIds,
            idOf: (ind) => ind.id ?? '',
            nameOf: (ind) => ind.name,
            isLoading: indicatorBloc.state.status == IndicatorStatus.loading,
          );

    if (!mounted || savedIds == null) {
      return;
    }

    discussionBloc.add(
      UpdateDiscussionEvent(
        discussion.copyWith(
          indicatorIds: savedIds.toList(),
          indicators: const [],
        ),
      ),
    );
  }

  Future<Set<String>?> _showCatalogSelectorDialog<T>({
    required String title,
    required Object bloc,
    required List<T> items,
    required Set<String> selectedIds,
    required String Function(T) idOf,
    required String Function(T) nameOf,
    required bool isLoading,
  }) {
    return showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                child: _buildCatalogList(
                  items: items,
                  selectedIds: selectedIds,
                  idOf: idOf,
                  nameOf: nameOf,
                  isLoading: isLoading,
                  setDialogState: setDialogState,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, Set<String>.from(selectedIds)),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Set<String>?> _showCatalogSelectorSheet<T>({
    required String title,
    required Object bloc,
    required List<T> items,
    required Set<String> selectedIds,
    required String Function(T) idOf,
    required String Function(T) nameOf,
    required bool isLoading,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setDialogState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Flexible(
                      child: _buildCatalogList(
                        items: items,
                        selectedIds: selectedIds,
                        idOf: idOf,
                        nameOf: nameOf,
                        isLoading: isLoading,
                        setDialogState: setDialogState,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(sheetContext, Set<String>.from(selectedIds)),
                            child: const Text('Guardar'),
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

  Widget _buildCatalogList<T>({
    required List<T> items,
    required Set<String> selectedIds,
    required String Function(T) idOf,
    required String Function(T) nameOf,
    required bool isLoading,
    required void Function(VoidCallback fn) setDialogState,
  }) {
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return const Center(child: Text('No hay elementos disponibles.'));
    }

    return ListView(
      shrinkWrap: true,
      children: items
          .where((item) => idOf(item).isNotEmpty)
          .map(
            (item) => CheckboxListTile(
              dense: true,
              value: selectedIds.contains(idOf(item)),
              title: Text(nameOf(item)),
              onChanged: (checked) {
                setDialogState(() {
                  if (checked == true) {
                    selectedIds.add(idOf(item));
                  } else {
                    selectedIds.remove(idOf(item));
                  }
                });
              },
            ),
          )
          .toList(growable: false),
    );
  }

  String _statusLabel(DiscussionRecordStatus status) {
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

  Color _statusAccent(DiscussionRecordStatus status, AppSemanticColors semantic) {
    switch (status) {
      case DiscussionRecordStatus.newDiscussion:
        return semantic.statusNew;
      case DiscussionRecordStatus.review:
        return semantic.statusReview;
      case DiscussionRecordStatus.inProgress:
        return semantic.statusInProgress;
      case DiscussionRecordStatus.resolved:
        return semantic.statusResolved;
      case DiscussionRecordStatus.unknown:
        return Theme.of(context).colorScheme.outline;
    }
  }

  void _changeDiscussionStatus(
    Discussion discussion,
    DiscussionRecordStatus nextStatus,
  ) {
    final discussionId = discussion.id;
    if (discussionId == null || discussionId.isEmpty) {
      return;
    }

    context.read<DiscussionBloc>().add(
      ChangeDiscussionStatusEvent(
        discussionId: discussionId,
        status: nextStatus,
      ),
    );
  }

  Future<void> _openAssignmentsDialog(Discussion discussion) async {
    final discussionId = discussion.id;
    if (discussionId == null || discussionId.isEmpty) {
      return;
    }

    final bloc = context.read<DiscussionBloc>();
    bloc.add(const LoadAssignableDevelopersEvent());

    final selectedIds = discussion.assignedDevelopers
        .map((developer) => developer.id)
        .toSet();

    final compactLayout = _isCompactLayout(context);
    final savedIds = compactLayout
        ? await _showAssignmentsBottomSheet(bloc, selectedIds)
        : await _showAssignmentsDialog(bloc, selectedIds);

    if (!mounted || savedIds == null) {
      return;
    }

    bloc.add(
      ReplaceDiscussionAssignmentsEvent(
        discussionId: discussionId,
        developerUserIds: _sortedIds(savedIds),
      ),
    );
  }

  Future<Set<String>?> _showAssignmentsDialog(
    DiscussionBloc bloc,
    Set<String> selectedIds,
  ) {
    return showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text('Asignar developers'),
                content: SizedBox(
                  width: 420,
                  child: _buildAssignableDevelopersList(
                    bloc: bloc,
                    selectedIds: selectedIds,
                    setDialogState: setDialogState,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      final state = bloc.state;
                      final currentUser = context.read<AuthBloc>().state.session?.user;
                      if (currentUser == null || !currentUser.isDeveloper) {
                        return;
                      }
                      if (!state.assignableDevelopers
                          .any((developer) => developer.id == currentUser.id)) {
                        return;
                      }
                      setDialogState(() {
                        selectedIds.add(currentUser.id);
                      });
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Asignarme'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, Set<String>.from(selectedIds)),
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<Set<String>?> _showAssignmentsBottomSheet(
    DiscussionBloc bloc,
    Set<String> selectedIds,
  ) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: bloc,
          child: StatefulBuilder(
            builder: (sheetContext, setDialogState) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Asignar developers',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Flexible(
                        child: _buildAssignableDevelopersList(
                          bloc: bloc,
                          selectedIds: selectedIds,
                          setDialogState: setDialogState,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(sheetContext, Set<String>.from(selectedIds)),
                              child: const Text('Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAssignableDevelopersList({
    required DiscussionBloc bloc,
    required Set<String> selectedIds,
    required void Function(VoidCallback fn) setDialogState,
  }) {
    return BlocBuilder<DiscussionBloc, DiscussionState>(
      builder: (context, state) {
        if (state.isLoadingAssignableDevelopers &&
            state.assignableDevelopers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.assignableDevelopers.isEmpty) {
          return const Text('No hay developers disponibles.');
        }

        return ListView(
          shrinkWrap: true,
          children: state.assignableDevelopers
              .map(
                (developer) => CheckboxListTile(
                  dense: true,
                  value: selectedIds.contains(developer.id),
                  title: Text(developer.fullName),
                  subtitle: developer.email == null ? null : Text(developer.email!),
                  onChanged: (checked) {
                    setDialogState(() {
                      if (checked == true) {
                        selectedIds.add(developer.id);
                      } else {
                        selectedIds.remove(developer.id);
                      }
                    });
                  },
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  bool _isStatusBusy(String? discussionId) {
    final state = context.watch<DiscussionBloc>().state;
    return discussionId != null &&
        discussionId.isNotEmpty &&
        state.isUpdatingStatus &&
        state.operationDiscussionId == discussionId;
  }

  bool _isAssignmentsBusy(String? discussionId) {
    final state = context.watch<DiscussionBloc>().state;
    return discussionId != null &&
        discussionId.isNotEmpty &&
        state.isUpdatingAssignments &&
        state.operationDiscussionId == discussionId;
  }

  bool _isCompactLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width < AppBreakpoints.compact;
  }

  String _formatShortDateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');

    return '$day/$month $hh:$mm';
  }

  String _normalizedTitle(String title) {
    final value = title.trim();
    return value.isEmpty ? '(Sin titulo)' : value;
  }

  String _creatorDisplayName(DiscussionCreator? creator) {
    if (creator == null) {
      return 'Sin creador';
    }

    final fullName = creator.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }

    final email = creator.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return creator.id;
  }

  String _initials(String fullName) {
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

    return '${parts.first.substring(0, 1).toUpperCase()}${parts.last.substring(0, 1).toUpperCase()}';
  }

  List<String> _sortedIds(Set<String> ids) {
    final list = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final sorted = List<String>.from(list)..sort();
    return sorted;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showCopyableErrorDialog(String message) async {
    if (!mounted || _isCopyableErrorDialogOpen) {
      return;
    }

    _isCopyableErrorDialogOpen = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Error de carga de video'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              child: SelectableText(message),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: message));
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Error copiado al portapapeles.')),
                  );
              },
              icon: const Icon(Icons.copy_all_rounded),
              label: const Text('Copiar error'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );

    _isCopyableErrorDialogOpen = false;
  }

  String _timestampNow() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');
    return '$hh:$mm:$ss.$ms';
  }

  String _buildWebUploadDiagnosticBlock() {
    final baseUrl = NetworkConfig.fromEnvironment().baseUrl;
    final origin = Uri.base.origin;
    final endpointPath = ApiEndpoints.discussionMessageFilesByDiscussionId(
      Uri.encodeComponent(widget.discussionId),
    );
    final endpointUrl = _joinUrl(baseUrl, endpointPath);

    return 'Diagnostico web\n'
        '- Origen web: $origin\n'
        '- API_BASE_URL: $baseUrl\n'
        '- Endpoint upload: $endpointUrl\n'
        '- Requiere CORS para OPTIONS y POST con Authorization + Content-Type + Accept\n'
        '- Timestamp: ${DateTime.now().toIso8601String()}';
  }

  String _joinUrl(String baseUrl, String path) {
    final base = baseUrl.trim();
    final tail = path.startsWith('/') ? path.substring(1) : path;
    if (base.endsWith('/')) {
      return '$base$tail';
    }
    return '$base/$tail';
  }

  _OptimizedImageResult _optimizeImageForUpload({
    required Uint8List originalBytes,
    required String originalFileName,
  }) {
    try {
      final decoded = img.decodeImage(originalBytes);
      if (decoded == null) {
        return _OptimizedImageResult(
          bytes: originalBytes,
          fileName: originalFileName,
          wasOptimized: false,
        );
      }

      const maxSide = 1440;
      var processed = decoded;
      final longestSide = decoded.width >= decoded.height
          ? decoded.width
          : decoded.height;

      if (longestSide > maxSide) {
        final scale = maxSide / longestSide;
        final targetWidth = (decoded.width * scale).round();
        final targetHeight = (decoded.height * scale).round();
        processed = img.copyResize(
          decoded,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      var jpg = img.encodeJpg(processed, quality: 70);
      if (jpg.length > 900 * 1024) {
        jpg = img.encodeJpg(processed, quality: 58);
      }
      if (jpg.length > 700 * 1024) {
        jpg = img.encodeJpg(processed, quality: 48);
      }

      if (jpg.length >= originalBytes.length) {
        return _OptimizedImageResult(
          bytes: originalBytes,
          fileName: originalFileName,
          wasOptimized: false,
        );
      }

      return _OptimizedImageResult(
        bytes: Uint8List.fromList(jpg),
        fileName: _withJpgExtension(originalFileName),
        wasOptimized: true,
      );
    } catch (_) {
      return _OptimizedImageResult(
        bytes: originalBytes,
        fileName: originalFileName,
        wasOptimized: false,
      );
    }
  }

  String _withJpgExtension(String fileName) {
    final normalized = fileName.trim();
    if (normalized.isEmpty) {
      return 'image.jpg';
    }

    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex <= 0) {
      return '$normalized.jpg';
    }

    return '${normalized.substring(0, dotIndex)}.jpg';
  }
}

class _OptimizedImageResult {
  const _OptimizedImageResult({
    required this.bytes,
    required this.fileName,
    required this.wasOptimized,
  });

  final Uint8List bytes;
  final String fileName;
  final bool wasOptimized;
}

enum _MessageAction { edit, delete }

enum _AttachmentOption {
  image,
  audio,
  video,
  file;

  String get label {
    switch (this) {
      case _AttachmentOption.image:
        return 'Imagen';
      case _AttachmentOption.audio:
        return 'Audio';
      case _AttachmentOption.video:
        return 'Video';
      case _AttachmentOption.file:
        return 'Archivo';
    }
  }

  IconData get icon {
    switch (this) {
      case _AttachmentOption.image:
        return Icons.image_outlined;
      case _AttachmentOption.audio:
        return Icons.audiotrack_outlined;
      case _AttachmentOption.video:
        return Icons.videocam_outlined;
      case _AttachmentOption.file:
        return Icons.attach_file_rounded;
    }
  }

  DiscussionMessageType get type {
    switch (this) {
      case _AttachmentOption.image:
        return DiscussionMessageType.image;
      case _AttachmentOption.audio:
        return DiscussionMessageType.audio;
      case _AttachmentOption.video:
        return DiscussionMessageType.video;
      case _AttachmentOption.file:
        return DiscussionMessageType.file;
    }
  }

  FileType get filePickerType {
    switch (this) {
      case _AttachmentOption.image:
      case _AttachmentOption.audio:
      case _AttachmentOption.video:
        return FileType.custom;
      case _AttachmentOption.file:
        return FileType.any;
    }
  }

  List<String>? get allowedExtensions {
    switch (this) {
      case _AttachmentOption.image:
        return const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif'];
      case _AttachmentOption.audio:
        return const ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'opus', 'flac', 'amr'];
      case _AttachmentOption.video:
        return const ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', '3gp'];
      case _AttachmentOption.file:
        return null;
    }
  }
}
