sealed class NotificationEvent {
  const NotificationEvent();
}

class InitializeNotificationsEvent extends NotificationEvent {
  const InitializeNotificationsEvent();
}

/// Cambio de la sesion que afecta a las notificaciones.
///
/// - [isAuthenticated]: hay un usuario con JWT valido; habilita el registro
///   del token FCM (`/workspace/devices` es global, no depende de la
///   organizacion).
/// - [isWorkspaceReady]: ademas hay organizacion activa validada contra
///   `/me/context` y la app ya puede navegar al Workspace (termino el splash).
///   Recien ahi se abre la discussion de una notificacion tocada.
class NotificationAuthStateChangedEvent extends NotificationEvent {
  const NotificationAuthStateChangedEvent({
    required this.isAuthenticated,
    required this.isWorkspaceReady,
  });

  final bool isAuthenticated;
  final bool isWorkspaceReady;
}

class NotificationTokenRefreshedEvent extends NotificationEvent {
  const NotificationTokenRefreshedEvent(this.token);

  final String token;
}

class NotificationForegroundMessageReceivedEvent extends NotificationEvent {
  const NotificationForegroundMessageReceivedEvent(this.data);

  final Map<String, String> data;
}

class NotificationOpenedEvent extends NotificationEvent {
  const NotificationOpenedEvent({required this.data, required this.source});

  final Map<String, String> data;
  final String source;
}

class NotificationNavigationHandledEvent extends NotificationEvent {
  const NotificationNavigationHandledEvent();
}

class NotificationActiveDiscussionChangedEvent extends NotificationEvent {
  const NotificationActiveDiscussionChangedEvent({required this.discussionId});

  final String? discussionId;
}

class NotificationAppLifecycleResumedEvent extends NotificationEvent {
  const NotificationAppLifecycleResumedEvent();
}
