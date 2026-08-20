import '../../../discussions/domain/entities/discussion.dart';
import '../../domain/entities/shared_content.dart';

enum ShareIntentSendStatus { idle, sending, success, error }

class ShareIntentState {
  const ShareIntentState({
    this.initialized = false,
    this.isAuthenticated = false,
    this.pendingContent,
    this.lastSignature,
    this.composerRequestVersion = 0,
    this.discussions = const [],
    this.isLoadingDiscussions = false,
    this.discussionsErrorMessage = '',
    this.searchQuery = '',
    this.selectedDiscussionId,
    this.sendStatus = ShareIntentSendStatus.idle,
    this.sendErrorMessage = '',
    this.lastSentDiscussionId,
    this.sendSuccessVersion = 0,
    this.infoMessage = '',
    this.infoMessageVersion = 0,
  });

  final bool initialized;
  final bool isAuthenticated;
  final SharedContent? pendingContent;
  final String? lastSignature;
  final int composerRequestVersion;
  final List<Discussion> discussions;
  final bool isLoadingDiscussions;
  final String discussionsErrorMessage;
  final String searchQuery;
  final String? selectedDiscussionId;
  final ShareIntentSendStatus sendStatus;
  final String sendErrorMessage;
  final String? lastSentDiscussionId;
  final int sendSuccessVersion;
  final String infoMessage;
  final int infoMessageVersion;

  List<Discussion> get filteredDiscussions {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return discussions;
    }

    return discussions
        .where((discussion) {
          final title = discussion.title.toLowerCase();
          return title.contains(query);
        })
        .toList(growable: false);
  }

  ShareIntentState copyWith({
    bool? initialized,
    bool? isAuthenticated,
    SharedContent? pendingContent,
    bool clearPendingContent = false,
    String? lastSignature,
    int? composerRequestVersion,
    List<Discussion>? discussions,
    bool? isLoadingDiscussions,
    String? discussionsErrorMessage,
    String? searchQuery,
    String? selectedDiscussionId,
    bool clearSelectedDiscussionId = false,
    ShareIntentSendStatus? sendStatus,
    String? sendErrorMessage,
    String? lastSentDiscussionId,
    bool clearLastSentDiscussionId = false,
    int? sendSuccessVersion,
    String? infoMessage,
    int? infoMessageVersion,
  }) {
    return ShareIntentState(
      initialized: initialized ?? this.initialized,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      pendingContent: clearPendingContent
          ? null
          : pendingContent ?? this.pendingContent,
      lastSignature: lastSignature ?? this.lastSignature,
      composerRequestVersion:
          composerRequestVersion ?? this.composerRequestVersion,
      discussions: discussions ?? this.discussions,
      isLoadingDiscussions: isLoadingDiscussions ?? this.isLoadingDiscussions,
      discussionsErrorMessage:
          discussionsErrorMessage ?? this.discussionsErrorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDiscussionId: clearSelectedDiscussionId
          ? null
          : selectedDiscussionId ?? this.selectedDiscussionId,
      sendStatus: sendStatus ?? this.sendStatus,
      sendErrorMessage: sendErrorMessage ?? this.sendErrorMessage,
      lastSentDiscussionId: clearLastSentDiscussionId
          ? null
          : lastSentDiscussionId ?? this.lastSentDiscussionId,
      sendSuccessVersion: sendSuccessVersion ?? this.sendSuccessVersion,
      infoMessage: infoMessage ?? this.infoMessage,
      infoMessageVersion: infoMessageVersion ?? this.infoMessageVersion,
    );
  }
}
