import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/discussion_message.dart';
import '../../domain/entities/discussion_message_page.dart';
import '../../domain/usecases/create_discussion_message.dart' as create_uc;
import '../../domain/usecases/delete_discussion_message.dart' as delete_uc;
import '../../domain/usecases/get_discussion_messages.dart' as get_uc;
import '../../domain/usecases/upload_discussion_message_attachment.dart'
  as upload_attachment_uc;
import '../../domain/usecases/update_discussion_message.dart' as update_uc;
import 'discussion_message_event.dart';
import 'discussion_message_state.dart';

class DiscussionMessageBloc
    extends Bloc<DiscussionMessageEvent, DiscussionMessageState> {
  DiscussionMessageBloc({
    required get_uc.GetDiscussionMessages getDiscussionMessages,
    required create_uc.CreateDiscussionMessage createDiscussionMessage,
    required upload_attachment_uc.UploadDiscussionMessageAttachment
    uploadDiscussionMessageAttachment,
    required update_uc.UpdateDiscussionMessage updateDiscussionMessage,
    required delete_uc.DeleteDiscussionMessage deleteDiscussionMessage,
  }) : _getDiscussionMessages = getDiscussionMessages,
       _createDiscussionMessage = createDiscussionMessage,
       _uploadDiscussionMessageAttachment = uploadDiscussionMessageAttachment,
       _updateDiscussionMessage = updateDiscussionMessage,
       _deleteDiscussionMessage = deleteDiscussionMessage,
       super(const DiscussionMessageState()) {
    on<LoadDiscussionMessagesEvent>(_onLoadDiscussionMessages);
    on<LoadMoreDiscussionMessagesEvent>(_onLoadMoreDiscussionMessages);
     on<RefreshDiscussionMessagesEvent>(_onRefreshDiscussionMessages);
    on<CreateDiscussionMessageEvent>(_onCreateDiscussionMessage);
    on<CreateDiscussionAttachmentMessageEvent>(
      _onCreateDiscussionAttachmentMessage,
    );
    on<UpdateDiscussionMessageEvent>(_onUpdateDiscussionMessage);
    on<DeleteDiscussionMessageEvent>(_onDeleteDiscussionMessage);
  }

  final get_uc.GetDiscussionMessages _getDiscussionMessages;
  final create_uc.CreateDiscussionMessage _createDiscussionMessage;
  final upload_attachment_uc.UploadDiscussionMessageAttachment
  _uploadDiscussionMessageAttachment;
  final update_uc.UpdateDiscussionMessage _updateDiscussionMessage;
  final delete_uc.DeleteDiscussionMessage _deleteDiscussionMessage;

  Future<void> _onLoadDiscussionMessages(
    LoadDiscussionMessagesEvent event,
    Emitter<DiscussionMessageState> emit,
  ) async {
    if (event.page == 1 &&
        state.status == DiscussionMessageStatus.loading &&
        state.activeDiscussionId == event.discussionId) {
      return;
    }

    final shouldReset =
        state.activeDiscussionId != event.discussionId || event.page == 1;

    emit(
      state.copyWith(
        status: DiscussionMessageStatus.loading,
        activeDiscussionId: event.discussionId,
        page: shouldReset
            ? DiscussionMessagePage.empty.copyWith(limit: event.limit)
            : state.page,
        errorMessage: '',
        isLoadingMore: false,
        isRefreshing: false,
        isSending: false,
        isUpdating: false,
        clearUpdatingMessageId: true,
      ),
    );

    final result = await _getDiscussionMessages(
      get_uc.GetDiscussionMessagesParams(
        discussionId: event.discussionId,
        page: event.page,
        limit: event.limit,
        type: event.type,
      ),
    );

    if (result is Success<DiscussionMessagePage>) {
      final sortedData = _sortByBackendChronology(result.data.data);

      if (kDebugMode) {
        debugPrint(
          '[DISCUSSION] state updated - ${_timestampNow()} - '
          'discussionId=${event.discussionId} messages=${sortedData.length}',
        );
      }

      emit(
        state.copyWith(
          status: DiscussionMessageStatus.success,
          activeDiscussionId: event.discussionId,
          page: result.data.copyWith(data: sortedData),
          errorMessage: '',
          isLoadingMore: false,
          isRefreshing: false,
          isSending: false,
          isUpdating: false,
          clearUpdatingMessageId: true,
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionMessagePage>) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: result.failure.message,
          isLoadingMore: false,
          isRefreshing: false,
          isSending: false,
          isUpdating: false,
          clearUpdatingMessageId: true,
        ),
      );
    }
  }

  Future<void> _onRefreshDiscussionMessages(
    RefreshDiscussionMessagesEvent event,
    Emitter<DiscussionMessageState> emit,
  ) async {
    if (state.activeDiscussionId != event.discussionId) {
      add(
        LoadDiscussionMessagesEvent(
          discussionId: event.discussionId,
          page: 1,
          limit: event.limit,
          type: event.type,
        ),
      );
      return;
    }

    if (state.isRefreshing || state.status == DiscussionMessageStatus.loading) {
      return;
    }

    emit(state.copyWith(isRefreshing: true, errorMessage: ''));

    final result = await _getDiscussionMessages(
      get_uc.GetDiscussionMessagesParams(
        discussionId: event.discussionId,
        page: 1,
        limit: event.limit,
        type: event.type,
      ),
    );

    if (result is Success<DiscussionMessagePage>) {
      final sortedData = _sortByBackendChronology(result.data.data);

      emit(
        state.copyWith(
          status: DiscussionMessageStatus.success,
          activeDiscussionId: event.discussionId,
          page: result.data.copyWith(data: sortedData),
          errorMessage: '',
          isRefreshing: false,
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionMessagePage>) {
      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onLoadMoreDiscussionMessages(
    LoadMoreDiscussionMessagesEvent event,
    Emitter<DiscussionMessageState> emit,
  ) async {
    if (state.activeDiscussionId != event.discussionId ||
        state.status == DiscussionMessageStatus.loading ||
        state.isLoadingMore ||
        !state.page.hasNext) {
      return;
    }

    final nextPage = state.page.page + 1;

    emit(state.copyWith(isLoadingMore: true, errorMessage: ''));

    final result = await _getDiscussionMessages(
      get_uc.GetDiscussionMessagesParams(
        discussionId: event.discussionId,
        page: nextPage,
        limit: event.limit,
        type: event.type,
      ),
    );

    if (result is Success<DiscussionMessagePage>) {
      final merged = _mergeByIdAndSort(state.page.data, result.data.data);

      emit(
        state.copyWith(
          status: DiscussionMessageStatus.success,
          page: result.data.copyWith(data: merged),
          errorMessage: '',
          isLoadingMore: false,
          isRefreshing: false,
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionMessagePage>) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: result.failure.message,
          isLoadingMore: false,
          isRefreshing: false,
        ),
      );
    }
  }

  Future<void> _onCreateDiscussionMessage(
    CreateDiscussionMessageEvent event,
    Emitter<DiscussionMessageState> emit,
  ) async {
    final content = event.content.trim();
    if (content.isEmpty) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: 'El contenido del mensaje es obligatorio.',
          isSending: false,
        ),
      );
      return;
    }

    emit(state.copyWith(isSending: true, isRefreshing: false, errorMessage: ''));

    final result = await _createDiscussionMessage(
      create_uc.CreateDiscussionMessageParams(
        discussionId: event.discussionId,
        content: content,
        type: event.type,
      ),
    );

    if (result is Success<DiscussionMessage>) {
      final created = result.data;
      final currentData = state.activeDiscussionId == event.discussionId
          ? state.page.data
          : const <DiscussionMessage>[];

      final alreadyExists = currentData.any((item) => item.id == created.id);
      final mergedData = _mergeByIdAndSort(currentData, [created]);

      final currentLimit = state.activeDiscussionId == event.discussionId
          ? state.page.limit
          : 50;
      final currentTotal = state.activeDiscussionId == event.discussionId
          ? state.page.total
          : 0;
      var mergedTotal = alreadyExists ? currentTotal : currentTotal + 1;
      if (mergedTotal < mergedData.length) {
        mergedTotal = mergedData.length;
      }

      final totalPages = mergedTotal == 0
          ? 0
          : (mergedTotal / currentLimit).ceil();

      emit(
        state.copyWith(
          status: DiscussionMessageStatus.success,
          activeDiscussionId: event.discussionId,
          page: DiscussionMessagePage(
            data: mergedData,
            page: 1,
            limit: currentLimit,
            total: mergedTotal,
            totalPages: totalPages,
          ),
          errorMessage: '',
          isRefreshing: false,
          isSending: false,
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionMessage>) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: result.failure.message,
          isRefreshing: false,
          isSending: false,
        ),
      );
    }
  }

  Future<void> _onUpdateDiscussionMessage(
    UpdateDiscussionMessageEvent event,
    Emitter<DiscussionMessageState> emit,
  ) async {
    final content = event.content.trim();
    if (content.isEmpty) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: 'El contenido del mensaje es obligatorio.',
          isUpdating: false,
          clearUpdatingMessageId: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isUpdating: true,
        updatingMessageId: event.messageId,
        isRefreshing: false,
        errorMessage: '',
      ),
    );

    final result = await _updateDiscussionMessage(
      update_uc.UpdateDiscussionMessageParams(
        discussionId: event.discussionId,
        messageId: event.messageId,
        content: content,
      ),
    );

    if (result is Success<DiscussionMessage>) {
      final updated = result.data;
      final data = state.activeDiscussionId == event.discussionId
          ? _mergeByIdAndSort(state.page.data, [updated])
          : state.page.data;

      emit(
        state.copyWith(
          status: DiscussionMessageStatus.success,
          page: state.page.copyWith(data: data),
          errorMessage: '',
          isRefreshing: false,
          isUpdating: false,
          clearUpdatingMessageId: true,
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionMessage>) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: result.failure.message,
          isRefreshing: false,
          isUpdating: false,
          clearUpdatingMessageId: true,
        ),
      );
    }
  }

  Future<void> _onCreateDiscussionAttachmentMessage(
    CreateDiscussionAttachmentMessageEvent event,
    Emitter<DiscussionMessageState> emit,
  ) async {
    if (!_isAttachmentType(event.type)) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage:
              'El tipo de adjunto debe ser IMAGE, AUDIO, VIDEO o FILE.',
          isSending: false,
        ),
      );
      return;
    }

    final fileName = event.fileName.trim();
    if (fileName.isEmpty || event.fileBytes.isEmpty) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: 'Debes seleccionar un archivo valido para adjuntar.',
          isSending: false,
        ),
      );
      return;
    }

    emit(state.copyWith(isSending: true, isRefreshing: false, errorMessage: ''));

    final result = await _uploadDiscussionMessageAttachment(
      upload_attachment_uc.UploadDiscussionMessageAttachmentParams(
        discussionId: event.discussionId,
        type: event.type,
        fileName: fileName,
        fileBytes: event.fileBytes,
        content: event.content?.trim(),
      ),
    );

    if (result is Success<DiscussionMessage>) {
      final created = result.data;
      final currentData = state.activeDiscussionId == event.discussionId
          ? state.page.data
          : const <DiscussionMessage>[];

      final alreadyExists = currentData.any((item) => item.id == created.id);
      final mergedData = _mergeByIdAndSort(currentData, [created]);

      final currentLimit = state.activeDiscussionId == event.discussionId
          ? state.page.limit
          : 50;
      final currentTotal = state.activeDiscussionId == event.discussionId
          ? state.page.total
          : 0;
      var mergedTotal = alreadyExists ? currentTotal : currentTotal + 1;
      if (mergedTotal < mergedData.length) {
        mergedTotal = mergedData.length;
      }

      final totalPages = mergedTotal == 0
          ? 0
          : (mergedTotal / currentLimit).ceil();

      emit(
        state.copyWith(
          status: DiscussionMessageStatus.success,
          activeDiscussionId: event.discussionId,
          page: DiscussionMessagePage(
            data: mergedData,
            page: 1,
            limit: currentLimit,
            total: mergedTotal,
            totalPages: totalPages,
          ),
          errorMessage: '',
          isRefreshing: false,
          isSending: false,
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionMessage>) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: result.failure.message,
          isRefreshing: false,
          isSending: false,
        ),
      );
    }
  }

  Future<void> _onDeleteDiscussionMessage(
    DeleteDiscussionMessageEvent event,
    Emitter<DiscussionMessageState> emit,
  ) async {
    if (state.deletingMessageId != null) {
      return;
    }

    emit(state.copyWith(deletingMessageId: event.messageId, errorMessage: ''));

    final result = await _deleteDiscussionMessage(
      delete_uc.DeleteDiscussionMessageParams(
        discussionId: event.discussionId,
        messageId: event.messageId,
      ),
    );

    if (result is Success<void>) {
      final updatedData = state.activeDiscussionId == event.discussionId
          ? state.page.data
              .where((m) => m.id != event.messageId)
              .toList(growable: false)
          : state.page.data;
      final newTotal =
          state.page.total > 0 ? state.page.total - 1 : 0;
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.success,
          page: state.page.copyWith(data: updatedData, total: newTotal),
          clearDeletingMessageId: true,
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<void>) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: result.failure.message,
          clearDeletingMessageId: true,
        ),
      );
    }
  }

  bool _isAttachmentType(DiscussionMessageType type) {
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

  List<DiscussionMessage> _mergeByIdAndSort(
    List<DiscussionMessage> current,
    List<DiscussionMessage> incoming,
  ) {
    final mapById = <String, DiscussionMessage>{
      for (final message in current) message.id: message,
    };

    for (final message in incoming) {
      mapById[message.id] = message;
    }

    return _sortByBackendChronology(mapById.values);
  }

  List<DiscussionMessage> _sortByBackendChronology(
    Iterable<DiscussionMessage> source,
  ) {
    final list = List<DiscussionMessage>.from(source);
    list.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate != null && bDate != null) {
        final dateComparison = aDate.compareTo(bDate);
        if (dateComparison != 0) {
          return dateComparison;
        }
      } else if (aDate == null && bDate != null) {
        return -1;
      } else if (aDate != null && bDate == null) {
        return 1;
      }

      return a.id.compareTo(b.id);
    });

    return List<DiscussionMessage>.unmodifiable(list);
  }

  String _timestampNow() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');
    return '$hh:$mm:$ss.$ms';
  }
}
