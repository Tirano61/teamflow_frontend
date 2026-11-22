import '../../domain/entities/push_notification.dart';

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
    this.isSessionResolved = false,
    this.isWorkspaceReady = false,
    this.currentUserId = '',
    this.activeOrganizationId = '',
    this.organizationIds = const <String>[],
    this.currentFcmToken,
    this.lastRegisteredToken,
    this.pendingNotification,
    this.organizationSwitchRequestId,
    this.organizationSwitchRequestVersion = 0,
    this.openDiscussionId,
    this.navigationRequestVersion = 0,
    this.infoMessage = '',
    this.infoMessageVersion = 0,
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

  /// Sesion con `/me/context` cargado y splash terminado: ya se puede validar
  /// el destinatario y la organizacion de una notificacion tocada.
  final bool isSessionResolved;

  /// Sesion con organizacion activa y navegacion al Workspace disponible: solo
  /// entonces una notificacion tocada abre su discussion.
  final bool isWorkspaceReady;

  /// Usuario autenticado segun `/me/context` (vacio sin contexto).
  final String currentUserId;
  final String activeOrganizationId;

  /// Organizaciones con Membership `ACTIVE` segun el ultimo `/me/context`.
  final List<String> organizationIds;
  final String? currentFcmToken;
  final String? lastRegisteredToken;

  /// Notificacion tocada que espera sesion, organizacion o Workspace listo
  /// para abrirse. Solo hay una: la ultima tocada reemplaza a la anterior.
  final PushNotification? pendingNotification;

  /// Organizacion a activar para abrir [pendingNotification]. La aplica la
  /// app con el flujo de Auth (`AuthOrganizationSelected`); este bloc nunca
  /// cambia `OrganizationContext`.
  final String? organizationSwitchRequestId;
  final int organizationSwitchRequestVersion;
  final String? openDiscussionId;
  final int navigationRequestVersion;

  /// Aviso para el usuario (por ejemplo, organizacion sin acceso). No incluye
  /// datos de la notificacion.
  final String infoMessage;
  final int infoMessageVersion;
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
    bool? isSessionResolved,
    bool? isWorkspaceReady,
    String? currentUserId,
    String? activeOrganizationId,
    List<String>? organizationIds,
    String? currentFcmToken,
    String? lastRegisteredToken,
    PushNotification? pendingNotification,
    String? organizationSwitchRequestId,
    int? organizationSwitchRequestVersion,
    String? openDiscussionId,
    int? navigationRequestVersion,
    String? infoMessage,
    int? infoMessageVersion,
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
    bool clearPendingNotification = false,
    bool clearOrganizationSwitchRequest = false,
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
      isSessionResolved: isSessionResolved ?? this.isSessionResolved,
      isWorkspaceReady: isWorkspaceReady ?? this.isWorkspaceReady,
      currentUserId: currentUserId ?? this.currentUserId,
      activeOrganizationId: activeOrganizationId ?? this.activeOrganizationId,
      organizationIds: organizationIds ?? this.organizationIds,
      currentFcmToken: clearCurrentFcmToken
          ? null
          : currentFcmToken ?? this.currentFcmToken,
      lastRegisteredToken: clearLastRegisteredToken
          ? null
          : lastRegisteredToken ?? this.lastRegisteredToken,
      pendingNotification: clearPendingNotification
          ? null
          : pendingNotification ?? this.pendingNotification,
      organizationSwitchRequestId: clearOrganizationSwitchRequest
          ? null
          : organizationSwitchRequestId ?? this.organizationSwitchRequestId,
      organizationSwitchRequestVersion:
          organizationSwitchRequestVersion ??
          this.organizationSwitchRequestVersion,
      openDiscussionId: clearOpenDiscussionId
          ? null
          : openDiscussionId ?? this.openDiscussionId,
      navigationRequestVersion:
          navigationRequestVersion ?? this.navigationRequestVersion,
      infoMessage: infoMessage ?? this.infoMessage,
      infoMessageVersion: infoMessageVersion ?? this.infoMessageVersion,
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
      refreshRequestVersion:
          refreshRequestVersion ?? this.refreshRequestVersion,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
