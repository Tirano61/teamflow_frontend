import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../core/network/network_config.dart';
import '../../../../../core/organization/organization_context.dart';
import '../../../../work_modules/domain/entities/work_module.dart';
import '../../../../work_modules/presentation/bloc/work_module_bloc.dart';
import '../../../../work_modules/presentation/bloc/work_module_event.dart';
import '../../../../work_modules/presentation/bloc/work_module_state.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../discussion_messages/domain/entities/discussion_message.dart';
import '../../../../discussion_messages/presentation/bloc/discussion_message_bloc.dart';
import '../../../../discussion_messages/presentation/bloc/discussion_message_event.dart';
import '../../../../discussion_messages/presentation/bloc/discussion_message_state.dart';
import '../../../../components/domain/entities/component.dart';
import '../../../../components/presentation/bloc/component_bloc.dart';
import '../../../../components/presentation/bloc/component_event.dart';
import '../../../../components/presentation/bloc/component_state.dart';
import '../../../../notifications/presentation/bloc/notification_bloc.dart';
import '../../../../notifications/presentation/bloc/notification_event.dart';
import '../../../../notifications/presentation/bloc/notification_state.dart';
import '../../../../tags/presentation/bloc/tag_bloc.dart';
import '../../../../tags/presentation/bloc/tag_event.dart';
import '../../../../tags/presentation/bloc/tag_state.dart';
import '../../../domain/entities/discussion.dart';
import '../../bloc/discussion_bloc.dart';
import '../../bloc/discussion_event.dart';
import '../../bloc/discussion_state.dart';
import 'discussion_attachment_option.dart';
import 'discussion_detail_helpers.dart';
import 'discussion_image_optimizer.dart';
import 'widgets/discussion_composer.dart';
import 'widgets/discussion_conversation_list.dart';
import 'widgets/discussion_detail_dialogs.dart';
import 'widgets/discussion_detail_header.dart';
import 'widgets/discussion_missing_state.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _contentScrollController = ScrollController();

  bool _pendingComposerClear = false;
  bool _pendingAttachmentUpload = false;
  String? _markAsReadRequestedForDiscussionId;
  bool _routeObserverSubscribed = false;
  int _lastKnownMessageCount = 0;
  NotificationBloc? _notificationBloc;
  String? _hoveredMessageId;
  AttachmentOption? _lastAttachmentOption;
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
                final discussion =
                    resolveDiscussion(discussionState, widget.discussionId);

                return BlocBuilder<DiscussionMessageBloc, DiscussionMessageState>(
                  builder: (context, messageState) {
                    if (discussionState.status == DiscussionStatus.loading &&
                        discussion == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (discussion == null) {
                      return DiscussionMissingState(
                        onRetry: () {
                          _loadDiscussion();
                          _loadMessages();
                        },
                      );
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
          DiscussionComposer(
            discussionId: widget.discussionId,
            controller: _messageController,
            pendingAttachmentUpload: _pendingAttachmentUpload,
            onTextChanged: () => setState(() {}),
            onOpenAttachmentOptions: _openAttachmentOptions,
            onSend: _sendMessage,
          ),
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
        DiscussionDetailHeader(
          discussion: discussion,
          isDeveloper: isDeveloper,
          statusBusy: _isStatusBusy(discussion.id),
          assigneesBusy: _isAssignmentsBusy(discussion.id),
          isSending: messageState.isSending,
          embedded: widget.embedded,
          workModuleLabels: _extractWorkModuleLabels(discussion),
          componentLabels: _extractComponentLabels(discussion),
          onStatusSelected: (status) =>
              _changeDiscussionStatus(discussion, status),
          onOpenStatusSheet: () => _openStatusBottomSheet(discussion),
          onOpenAssignments: () => _openAssignmentsDialog(discussion),
          onOpenWorkModuleSelector: () => _openWorkModuleSelector(discussion),
          onOpenComponentSelector: () => _openComponentSelector(discussion),
          onClose: widget.onClose,
        ),
        Expanded(
          child: Stack(
            children: [
              DiscussionConversationList(
                messageState: messageState,
                currentUserId: currentUserId,
                scrollController: _contentScrollController,
                hoveredMessageId: _hoveredMessageId,
                editingMessageId: _editingMessageId,
                editingController: _editingController,
                isSubmittingEdit: _submittingEdit,
                onMessageHoverChanged: _setMessageHover,
                onLoadMore: _loadMoreMessages,
                onEditMessage: _startInlineEdit,
                onDeleteMessage: _confirmDeleteMessage,
                onCancelEdit: _cancelInlineEdit,
                onSaveEdit: _saveInlineEdit,
                onOpenAttachment: _openAttachmentUrl,
              ),
              if (messageState.isRefreshing)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _setMessageHover(String messageId, bool hovering) {
    if (!kIsWeb) {
      return;
    }

    setState(() {
      if (hovering) {
        _hoveredMessageId = messageId;
      } else if (_hoveredMessageId == messageId) {
        _hoveredMessageId = null;
      }
    });
  }

  Future<void> _openStatusBottomSheet(Discussion discussion) async {
    final selected = await showDiscussionStatusSheet(context, discussion);

    if (!mounted || selected == null || selected == discussion.status) {
      return;
    }

    _changeDiscussionStatus(discussion, selected);
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

    final discussion = resolveDiscussion(state, widget.discussionId);
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

  void _loadMoreMessages() {
    final bloc = context.read<DiscussionMessageBloc>();
    final state = bloc.state;
    if (state.isLoadingMore || !state.page.hasNext) {
      return;
    }

    bloc.add(
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
    final AttachmentOption? selectedOption;
    if (isCompactLayout(context)) {
      selectedOption = await showAttachmentOptionsSheet(context);
    } else {
      selectedOption = await showAttachmentOptionsMenu(context);
    }

    if (!mounted || selectedOption == null) {
      return;
    }

    await _pickAndSendAttachment(selectedOption);
  }

  Future<void> _pickAndSendAttachment(AttachmentOption option) async {
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

      if (option == AttachmentOption.image) {
        final optimized = optimizeImageForUpload(
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
          option == AttachmentOption.video &&
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
    final confirmed = await showDeleteDiscussionMessageDialog(
      context: context,
      isAttachment: message.type != DiscussionMessageType.text,
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
          _lastAttachmentOption == AttachmentOption.video &&
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

  List<String> _extractWorkModuleLabels(Discussion discussion) {
    if (discussion.workModules.isNotEmpty) {
      return discussion.workModules
          .map((workModule) => workModule.name.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }

    final labelsById = {
      for (final item in context.read<WorkModuleBloc>().state.workModules)
        if ((item.id?.trim() ?? '').isNotEmpty) item.id!.trim(): item.name.trim(),
    };

    final labels = discussion.resolvedModuleIds
        .map((id) => labelsById[id.trim()] ?? '')
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);

    return labels;
  }

  List<String> _extractComponentLabels(Discussion discussion) {
    if (discussion.components.isNotEmpty) {
      return discussion.components
          .map((component) => component.name.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }

    final labelsById = {
      for (final item in context.read<ComponentBloc>().state.components)
        if ((item.id?.trim() ?? '').isNotEmpty) item.id!.trim(): item.name.trim(),
    };

    final labels = discussion.resolvedComponentIds
        .map((id) => labelsById[id.trim()] ?? '')
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);

    return labels;
  }

  void _loadCatalogs() {
    final appBloc = context.read<WorkModuleBloc>();
    if (appBloc.state.workModules.isEmpty &&
        appBloc.state.status != WorkModuleStatus.loading) {
      appBloc.add(const LoadWorkModulesEvent());
    }

    final componentBloc = context.read<ComponentBloc>();
    if (componentBloc.state.components.isEmpty &&
        componentBloc.state.status != ComponentStatus.loading) {
      componentBloc.add(const LoadComponentsEvent());
    }

    final tagBloc = context.read<TagBloc>();
    if (tagBloc.state.tags.isEmpty && tagBloc.state.status != TagStatus.loading) {
      tagBloc.add(const LoadTagsEvent());
    }
  }

  Future<void> _openWorkModuleSelector(Discussion discussion) async {
    final discussionId = discussion.id;
    if (discussionId == null || discussionId.isEmpty) {
      return;
    }

    final appBloc = context.read<WorkModuleBloc>();
    if (appBloc.state.workModules.isEmpty) {
      appBloc.add(const LoadWorkModulesEvent());
    }

    final discussionBloc = context.read<DiscussionBloc>();
    final selectedIds = Set<String>.from(discussion.resolvedModuleIds);

    final Set<String>? savedIds;
    if (isCompactLayout(context)) {
      savedIds = await showDiscussionCatalogSelectorSheet<WorkModule>(
        context: context,
        title: 'Aplicaciones',
        items: appBloc.state.workModules,
        selectedIds: selectedIds,
        idOf: (app) => app.id ?? '',
        nameOf: (app) => app.name,
        isLoading: appBloc.state.status == WorkModuleStatus.loading,
      );
    } else {
      savedIds = await showDiscussionCatalogSelectorDialog<WorkModule>(
        context: context,
        title: 'Aplicaciones',
        items: appBloc.state.workModules,
        selectedIds: selectedIds,
        idOf: (app) => app.id ?? '',
        nameOf: (app) => app.name,
        isLoading: appBloc.state.status == WorkModuleStatus.loading,
      );
    }

    if (!mounted || savedIds == null) {
      return;
    }

    discussionBloc.add(
      UpdateDiscussionEvent(
        discussion.copyWith(
          moduleIds: savedIds.toList(),
          workModules: const [],
        ),
      ),
    );
  }

  Future<void> _openComponentSelector(Discussion discussion) async {
    final discussionId = discussion.id;
    if (discussionId == null || discussionId.isEmpty) {
      return;
    }

    final componentBloc = context.read<ComponentBloc>();
    if (componentBloc.state.components.isEmpty) {
      componentBloc.add(const LoadComponentsEvent());
    }

    final discussionBloc = context.read<DiscussionBloc>();
    final selectedIds = Set<String>.from(discussion.resolvedComponentIds);

    final Set<String>? savedIds;
    if (isCompactLayout(context)) {
      savedIds = await showDiscussionCatalogSelectorSheet<Component>(
        context: context,
        title: 'Indicadores',
        items: componentBloc.state.components,
        selectedIds: selectedIds,
        idOf: (ind) => ind.id ?? '',
        nameOf: (ind) => ind.name,
        isLoading: componentBloc.state.status == ComponentStatus.loading,
      );
    } else {
      savedIds = await showDiscussionCatalogSelectorDialog<Component>(
        context: context,
        title: 'Indicadores',
        items: componentBloc.state.components,
        selectedIds: selectedIds,
        idOf: (ind) => ind.id ?? '',
        nameOf: (ind) => ind.name,
        isLoading: componentBloc.state.status == ComponentStatus.loading,
      );
    }

    if (!mounted || savedIds == null) {
      return;
    }

    discussionBloc.add(
      UpdateDiscussionEvent(
        discussion.copyWith(
          componentIds: savedIds.toList(),
          components: const [],
        ),
      ),
    );
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

    final Set<String>? savedIds;
    if (isCompactLayout(context)) {
      savedIds = await showDiscussionAssignmentsSheet(
        context: context,
        bloc: bloc,
        selectedIds: selectedIds,
      );
    } else {
      savedIds = await showDiscussionAssignmentsDialog(
        context: context,
        bloc: bloc,
        selectedIds: selectedIds,
      );
    }

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

    await showCopyableErrorDialog(context: context, message: message);

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

    // Solo diagnostico: se usa `organizationIdOrNull` para no lanzar
    // OrganizationNotSelectedException mientras se construye un mensaje de error.
    final organizationId = sl<OrganizationContext>().organizationIdOrNull;
    final endpointUrl = organizationId == null
        ? '(sin organizacion activa)'
        : _joinUrl(
            baseUrl,
            ApiEndpoints.discussionMessageFilesByDiscussionId(
              organizationId,
              Uri.encodeComponent(widget.discussionId),
            ),
          );

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
}
