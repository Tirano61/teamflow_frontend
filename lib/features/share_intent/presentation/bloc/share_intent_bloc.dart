import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../../../core/error/result.dart';
import '../../../discussion_messages/domain/entities/discussion_message.dart';
import '../../../discussion_messages/domain/usecases/upload_discussion_message_attachment.dart';
import '../../../discussions/domain/entities/discussion_filters.dart';
import '../../../discussions/domain/entities/discussion_page.dart';
import '../../../discussions/domain/usecases/get_discussions.dart';
import '../../data/datasources/share_intent_data_source.dart';
import '../../domain/entities/shared_content.dart';
import 'share_intent_event.dart';
import 'share_intent_state.dart';

class ShareIntentBloc extends Bloc<ShareIntentEvent, ShareIntentState> {
  ShareIntentBloc({
    required ShareIntentDataSource shareIntentDataSource,
    required GetDiscussions getDiscussions,
    required UploadDiscussionMessageAttachment uploadAttachment,
  }) : _shareIntentDataSource = shareIntentDataSource,
       _getDiscussions = getDiscussions,
       _uploadAttachment = uploadAttachment,
       super(const ShareIntentState()) {
    on<InitializeShareIntentEvent>(_onInitialize);
    on<ShareIntentAuthStatusChangedEvent>(_onAuthStatusChanged);
    on<ShareIntentMediaReceivedEvent>(_onMediaReceived);
    on<ShareIntentLoadDiscussionsEvent>(_onLoadDiscussions);
    on<ShareIntentSearchChangedEvent>(_onSearchChanged);
    on<ShareIntentDiscussionSelectedEvent>(_onDiscussionSelected);
    on<ShareIntentSendRequestedEvent>(_onSendRequested);
    on<ShareIntentCancelEvent>(_onCancel);
    on<ShareIntentMessageConsumedEvent>(_onMessageConsumed);
  }

  final ShareIntentDataSource _shareIntentDataSource;
  final GetDiscussions _getDiscussions;
  final UploadDiscussionMessageAttachment _uploadAttachment;

  StreamSubscription<List<SharedMediaFile>>? _mediaStreamSubscription;

  Future<void> _onInitialize(
    InitializeShareIntentEvent event,
    Emitter<ShareIntentState> emit,
  ) async {
    if (state.initialized) {
      return;
    }

    _mediaStreamSubscription = _shareIntentDataSource.getMediaStream().listen(
      (files) {
        add(ShareIntentMediaReceivedEvent(files: files, origin: 'stream'));
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[SHARE_INTENT] stream error: $error');
      },
    );

    emit(state.copyWith(initialized: true));

    try {
      final initialFiles = await _shareIntentDataSource.getInitialMedia();
      if (initialFiles.isNotEmpty) {
        add(
          ShareIntentMediaReceivedEvent(files: initialFiles, origin: 'initial'),
        );
      }
    } catch (error) {
      debugPrint('[SHARE_INTENT] getInitialMedia error: $error');
    }
  }

  void _onAuthStatusChanged(
    ShareIntentAuthStatusChangedEvent event,
    Emitter<ShareIntentState> emit,
  ) {
    var nextState = state.copyWith(isAuthenticated: event.isAuthenticated);

    if (event.isAuthenticated && nextState.pendingContent != null) {
      nextState = nextState.copyWith(
        composerRequestVersion: nextState.composerRequestVersion + 1,
      );
    }

    emit(nextState);
  }

  Future<void> _onMediaReceived(
    ShareIntentMediaReceivedEvent event,
    Emitter<ShareIntentState> emit,
  ) async {
    if (event.files.isEmpty) {
      return;
    }

    final firstFile = event.files.first;
    final signature = _buildSignature(firstFile);
    if (signature == state.lastSignature) {
      return;
    }

    final mapped = await _toSharedContent(firstFile, signature);
    if (mapped == null) {
      emit(
        state.copyWith(
          lastSignature: signature,
          infoMessage:
              'El contenido compartido no es compatible con esta version.',
          infoMessageVersion: state.infoMessageVersion + 1,
        ),
      );
      await _shareIntentDataSource.reset();
      return;
    }

    final multipleFilesMessage = event.files.length > 1
        ? 'Se recibieron ${event.files.length} archivos. Solo se procesara el primero.'
        : '';

    emit(
      state.copyWith(
        pendingContent: mapped,
        lastSignature: signature,
        sendStatus: ShareIntentSendStatus.idle,
        sendErrorMessage: '',
        clearLastSentDiscussionId: true,
        discussionsErrorMessage: '',
        infoMessage: multipleFilesMessage,
        infoMessageVersion: multipleFilesMessage.isEmpty
            ? state.infoMessageVersion
            : state.infoMessageVersion + 1,
      ),
    );

    await _shareIntentDataSource.reset();

    if (state.isAuthenticated) {
      emit(
        state.copyWith(
          composerRequestVersion: state.composerRequestVersion + 1,
        ),
      );
    }
  }

  Future<void> _onLoadDiscussions(
    ShareIntentLoadDiscussionsEvent event,
    Emitter<ShareIntentState> emit,
  ) async {
    emit(
      state.copyWith(isLoadingDiscussions: true, discussionsErrorMessage: ''),
    );

    final result = await _getDiscussions(
      filters: const DiscussionFilters(page: 1, limit: 100),
    );

    if (result is Success<DiscussionPage>) {
      final discussions = result.data.data;
      final preferred = event.preferredDiscussionId?.trim();

      var selectedId = state.selectedDiscussionId;
      if (preferred != null && preferred.isNotEmpty) {
        final exists = discussions.any(
          (discussion) => discussion.id == preferred,
        );
        if (exists) {
          selectedId = preferred;
        }
      }

      if (selectedId != null &&
          selectedId.isNotEmpty &&
          !discussions.any((discussion) => discussion.id == selectedId)) {
        selectedId = null;
      }

      emit(
        state.copyWith(
          isLoadingDiscussions: false,
          discussions: discussions,
          selectedDiscussionId: selectedId,
          clearSelectedDiscussionId:
              selectedId == null || selectedId.trim().isEmpty,
          discussionsErrorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionPage>) {
      emit(
        state.copyWith(
          isLoadingDiscussions: false,
          discussionsErrorMessage: result.failure.message,
        ),
      );
    }
  }

  void _onSearchChanged(
    ShareIntentSearchChangedEvent event,
    Emitter<ShareIntentState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onDiscussionSelected(
    ShareIntentDiscussionSelectedEvent event,
    Emitter<ShareIntentState> emit,
  ) {
    final discussionId = event.discussionId?.trim();
    if (discussionId == null || discussionId.isEmpty) {
      emit(state.copyWith(clearSelectedDiscussionId: true));
      return;
    }

    emit(state.copyWith(selectedDiscussionId: discussionId));
  }

  Future<void> _onSendRequested(
    ShareIntentSendRequestedEvent event,
    Emitter<ShareIntentState> emit,
  ) async {
    final pending = state.pendingContent;
    if (pending == null) {
      emit(
        state.copyWith(
          sendStatus: ShareIntentSendStatus.error,
          sendErrorMessage: 'No hay contenido compartido para enviar.',
        ),
      );
      return;
    }

    final discussionId = state.selectedDiscussionId?.trim();
    if (discussionId == null || discussionId.isEmpty) {
      emit(
        state.copyWith(
          sendStatus: ShareIntentSendStatus.error,
          sendErrorMessage: 'Debes seleccionar una discussion.',
        ),
      );
      return;
    }

    if (!_isSupportedType(pending.type)) {
      emit(
        state.copyWith(
          sendStatus: ShareIntentSendStatus.error,
          sendErrorMessage:
              'Solo se permiten archivos IMAGE, AUDIO, VIDEO o FILE.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        sendStatus: ShareIntentSendStatus.sending,
        sendErrorMessage: '',
      ),
    );

    try {
      final bytes = await XFile(pending.path).readAsBytes();
      if (bytes.isEmpty) {
        emit(
          state.copyWith(
            sendStatus: ShareIntentSendStatus.error,
            sendErrorMessage: 'No se pudo leer el archivo compartido.',
          ),
        );
        return;
      }

      if (pending.type == DiscussionMessageType.audio) {
        debugPrint(
          '[SHARE_INTENT] whatsapp-audio-check mime=${pending.mimeType ?? '-'} '
          'ext=${pending.extension ?? '-'} name=${pending.displayName}',
        );
      }

      final result = await _uploadAttachment(
        UploadDiscussionMessageAttachmentParams(
          discussionId: discussionId,
          type: pending.type,
          fileName: pending.uploadFileName,
          fileBytes: bytes,
        ),
      );

      if (result is Success<DiscussionMessage>) {
        emit(
          state.copyWith(
            sendStatus: ShareIntentSendStatus.success,
            clearPendingContent: true,
            clearSelectedDiscussionId: true,
            sendErrorMessage: '',
            lastSentDiscussionId: discussionId,
            sendSuccessVersion: state.sendSuccessVersion + 1,
            searchQuery: '',
          ),
        );
        await _shareIntentDataSource.reset();
        return;
      }

      if (result is FailureResult<DiscussionMessage>) {
        emit(
          state.copyWith(
            sendStatus: ShareIntentSendStatus.error,
            sendErrorMessage: result.failure.message,
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          sendStatus: ShareIntentSendStatus.error,
          sendErrorMessage: 'No se pudo leer el archivo compartido.',
        ),
      );
    }
  }

  Future<void> _onCancel(
    ShareIntentCancelEvent event,
    Emitter<ShareIntentState> emit,
  ) async {
    emit(
      state.copyWith(
        clearPendingContent: true,
        clearSelectedDiscussionId: true,
        sendStatus: ShareIntentSendStatus.idle,
        sendErrorMessage: '',
        searchQuery: '',
      ),
    );

    await _shareIntentDataSource.reset();
  }

  void _onMessageConsumed(
    ShareIntentMessageConsumedEvent event,
    Emitter<ShareIntentState> emit,
  ) {
    emit(state.copyWith(infoMessage: ''));
  }

  String _buildSignature(SharedMediaFile file) {
    final parts = <String>[
      file.path.trim(),
      file.mimeType?.trim() ?? '',
      file.type.value,
      file.duration?.toString() ?? '',
    ];
    return parts.join('|');
  }

  Future<SharedContent?> _toSharedContent(
    SharedMediaFile file,
    String signature,
  ) async {
    final normalizedPath = file.path.trim();
    if (normalizedPath.isEmpty) {
      return null;
    }

    final type = _resolveType(file);
    if (!_isSupportedType(type)) {
      return null;
    }

    final displayName = _resolveDisplayName(normalizedPath);
    int? sizeBytes;
    try {
      sizeBytes = await XFile(normalizedPath).length();
    } catch (_) {
      sizeBytes = null;
    }

    return SharedContent(
      signature: signature,
      path: normalizedPath,
      type: type,
      displayName: displayName,
      mimeType: file.mimeType?.trim(),
      sizeBytes: sizeBytes,
      durationMs: file.duration,
      thumbnailPath: file.thumbnail?.trim(),
      receivedAt: DateTime.now(),
    );
  }

  DiscussionMessageType _resolveType(SharedMediaFile file) {
    final mimeType = file.mimeType?.trim().toLowerCase();
    if (mimeType != null && mimeType.isNotEmpty) {
      if (mimeType.startsWith('image/')) {
        return DiscussionMessageType.image;
      }
      if (mimeType.startsWith('audio/')) {
        return DiscussionMessageType.audio;
      }
      if (mimeType.startsWith('video/')) {
        return DiscussionMessageType.video;
      }

      if (_isKnownDocumentMime(mimeType)) {
        return DiscussionMessageType.file;
      }
    }

    switch (file.type) {
      case SharedMediaType.image:
        return DiscussionMessageType.image;
      case SharedMediaType.video:
        return DiscussionMessageType.video;
      case SharedMediaType.file:
        return _resolveTypeByExtension(file.path);
      case SharedMediaType.text:
      case SharedMediaType.url:
        return DiscussionMessageType.unknown;
    }
  }

  DiscussionMessageType _resolveTypeByExtension(String path) {
    final lower = path.toLowerCase();

    const imageExtensions = <String>{
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.webp',
      '.bmp',
      '.heic',
      '.heif',
      '.svg',
    };

    const audioExtensions = <String>{
      '.mp3',
      '.wav',
      '.m4a',
      '.aac',
      '.ogg',
      '.opus',
      '.flac',
      '.amr',
    };

    const videoExtensions = <String>{
      '.mp4',
      '.mov',
      '.avi',
      '.mkv',
      '.webm',
      '.m4v',
      '.3gp',
    };

    if (imageExtensions.any(lower.endsWith)) {
      return DiscussionMessageType.image;
    }

    if (audioExtensions.any(lower.endsWith)) {
      return DiscussionMessageType.audio;
    }

    if (videoExtensions.any(lower.endsWith)) {
      return DiscussionMessageType.video;
    }

    return DiscussionMessageType.file;
  }

  String _resolveDisplayName(String path) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last.trim();
      if (last.isNotEmpty) {
        return last;
      }
    }

    final normalized = path.replaceAll('\\', '/').trim();
    if (normalized.contains('/')) {
      final last = normalized.split('/').last.trim();
      if (last.isNotEmpty) {
        return last;
      }
    }

    return 'shared_file';
  }

  bool _isKnownDocumentMime(String mimeType) {
    const supported = <String>{
      'application/pdf',
      'text/plain',
      'application/msword',
      'application/vnd.ms-excel',
      'application/vnd.ms-powerpoint',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/zip',
      'application/x-zip-compressed',
      'application/vnd.rar',
      'application/x-rar-compressed',
      'application/octet-stream',
    };

    return supported.contains(mimeType);
  }

  bool _isSupportedType(DiscussionMessageType type) {
    switch (type) {
      case DiscussionMessageType.image:
      case DiscussionMessageType.audio:
      case DiscussionMessageType.video:
      case DiscussionMessageType.file:
        return true;
      case DiscussionMessageType.text:
      case DiscussionMessageType.unknown:
        return false;
    }
  }

  @override
  Future<void> close() async {
    await _mediaStreamSubscription?.cancel();
    return super.close();
  }
}
