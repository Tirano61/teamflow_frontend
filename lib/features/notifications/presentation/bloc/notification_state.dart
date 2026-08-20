enum NotificationStatus { initial, initializing, ready, error }

enum NotificationSyncType {
  none,
  discussionAndMessages,
  messagesOnly,
  contextOnly,
}

class NotificationState {
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.pushSupported = true,
    this.initialized = false,
    this.permissionRequested = false,
    this.isAuthenticated = false,
    this.currentFcmToken,
    this.lastRegisteredToken,
    this.pendingDiscussionId,
    this.openDiscussionId,
    this.navigationRequestVersion = 0,
    this.lastNotificationType = '',
    this.activeDiscussionId,
    this.notificationDiscussionId,
    this.notificationEventVersion = 0,
    this.syncType = NotificationSyncType.none,
    this.syncDiscussionId,
    this.syncVersion = 0,
    this.refreshDiscussionId,
    this.refreshRequestVersion = 0,
    this.errorMessage = '',
  });

  final NotificationStatus status;
  final bool pushSupported;
  final bool initialized;
  final bool permissionRequested;
  final bool isAuthenticated;
  final String? currentFcmToken;
  final String? lastRegisteredToken;
  final String? pendingDiscussionId;
  final String? openDiscussionId;
  final int navigationRequestVersion;
  final String lastNotificationType;
  final String? activeDiscussionId;
  final String? notificationDiscussionId;
  final int notificationEventVersion;
  final NotificationSyncType syncType;
  final String? syncDiscussionId;
  final int syncVersion;
  final String? refreshDiscussionId;
  final int refreshRequestVersion;
  final String errorMessage;

  NotificationState copyWith({
    NotificationStatus? status,
    bool? pushSupported,
    bool? initialized,
    bool? permissionRequested,
    bool? isAuthenticated,
    String? currentFcmToken,
    String? lastRegisteredToken,
    String? pendingDiscussionId,
    String? openDiscussionId,
    int? navigationRequestVersion,
    String? lastNotificationType,
    String? activeDiscussionId,
    String? notificationDiscussionId,
    int? notificationEventVersion,
    NotificationSyncType? syncType,
    String? syncDiscussionId,
    int? syncVersion,
    String? refreshDiscussionId,
    int? refreshRequestVersion,
    String? errorMessage,
    bool clearCurrentFcmToken = false,
    bool clearLastRegisteredToken = false,
    bool clearPendingDiscussionId = false,
    bool clearOpenDiscussionId = false,
    bool clearActiveDiscussionId = false,
    bool clearNotificationDiscussionId = false,
    bool clearSyncDiscussionId = false,
    bool clearRefreshDiscussionId = false,
  }) {
    return NotificationState(
      status: status ?? this.status,
      pushSupported: pushSupported ?? this.pushSupported,
      initialized: initialized ?? this.initialized,
      permissionRequested: permissionRequested ?? this.permissionRequested,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentFcmToken: clearCurrentFcmToken
          ? null
          : currentFcmToken ?? this.currentFcmToken,
      lastRegisteredToken: clearLastRegisteredToken
          ? null
          : lastRegisteredToken ?? this.lastRegisteredToken,
      pendingDiscussionId: clearPendingDiscussionId
          ? null
          : pendingDiscussionId ?? this.pendingDiscussionId,
      openDiscussionId: clearOpenDiscussionId
          ? null
          : openDiscussionId ?? this.openDiscussionId,
      navigationRequestVersion:
          navigationRequestVersion ?? this.navigationRequestVersion,
      lastNotificationType: lastNotificationType ?? this.lastNotificationType,
        activeDiscussionId: clearActiveDiscussionId
          ? null
          : activeDiscussionId ?? this.activeDiscussionId,
        notificationDiscussionId: clearNotificationDiscussionId
          ? null
          : notificationDiscussionId ?? this.notificationDiscussionId,
        notificationEventVersion:
          notificationEventVersion ?? this.notificationEventVersion,
        syncType: syncType ?? this.syncType,
        syncDiscussionId: clearSyncDiscussionId
          ? null
          : syncDiscussionId ?? this.syncDiscussionId,
        syncVersion: syncVersion ?? this.syncVersion,
        refreshDiscussionId: clearRefreshDiscussionId
          ? null
          : refreshDiscussionId ?? this.refreshDiscussionId,
        refreshRequestVersion: refreshRequestVersion ?? this.refreshRequestVersion,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
