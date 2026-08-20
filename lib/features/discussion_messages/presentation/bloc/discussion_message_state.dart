import '../../domain/entities/discussion_message.dart';
import '../../domain/entities/discussion_message_page.dart';

enum DiscussionMessageStatus { initial, loading, success, error }

class DiscussionMessageState {
  const DiscussionMessageState({
    this.status = DiscussionMessageStatus.initial,
    this.page = DiscussionMessagePage.empty,
    this.activeDiscussionId = '',
    this.errorMessage = '',
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.isSending = false,
    this.isUpdating = false,
    this.updatingMessageId,
    this.deletingMessageId,
  });

  final DiscussionMessageStatus status;
  final DiscussionMessagePage page;
  final String activeDiscussionId;
  final String errorMessage;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool isSending;
  final bool isUpdating;
  final String? updatingMessageId;
  final String? deletingMessageId;

  bool get isDeleting => deletingMessageId != null;

  List<DiscussionMessage> get messages => page.data;

  DiscussionMessageState copyWith({
    DiscussionMessageStatus? status,
    DiscussionMessagePage? page,
    String? activeDiscussionId,
    String? errorMessage,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? isSending,
    bool? isUpdating,
    String? updatingMessageId,
    bool clearUpdatingMessageId = false,
    String? deletingMessageId,
    bool clearDeletingMessageId = false,
  }) {
    return DiscussionMessageState(
      status: status ?? this.status,
      page: page ?? this.page,
      activeDiscussionId: activeDiscussionId ?? this.activeDiscussionId,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSending: isSending ?? this.isSending,
      isUpdating: isUpdating ?? this.isUpdating,
      updatingMessageId: clearUpdatingMessageId
          ? null
          : updatingMessageId ?? this.updatingMessageId,
      deletingMessageId: clearDeletingMessageId
          ? null
          : deletingMessageId ?? this.deletingMessageId,
    );
  }
}
