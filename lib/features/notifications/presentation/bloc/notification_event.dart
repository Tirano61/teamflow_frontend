import '../../domain/entities/push_notification.dart';

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
/// - [isSessionResolved]: ademas `/me/context` ya se cargo (y no se esta
///   recargando) y termino el splash. Recien ahi se conocen [currentUserId] y
///   [organizationIds] para validar una notificacion tocada.
/// - [isWorkspaceReady]: ademas hay organizacion activa validada contra
///   `/me/context` y la app ya puede navegar al Workspace. Recien ahi se abre
///   la discussion de una notificacion tocada.
/// - [currentUserId]: usuario de `/me/context` (vacio si no se cargo).
/// - [activeOrganizationId]: organizacion activa (vacio si no hay).
/// - [organizationIds]: organizaciones con Membership `ACTIVE` del usuario
///   segun el ultimo `/me/context`.
class NotificationAuthStateChangedEvent extends NotificationEvent {
  const NotificationAuthStateChangedEvent({
    required this.isAuthenticated,
    required this.isSessionResolved,
    required this.isWorkspaceReady,
    required this.currentUserId,
    required this.activeOrganizationId,
    required this.organizationIds,
  });

  final bool isAuthenticated;
  final bool isSessionResolved;
  final bool isWorkspaceReady;
  final String currentUserId;
  final String activeOrganizationId;
  final List<String> organizationIds;
}

class NotificationTokenRefreshedEvent extends NotificationEvent {
  const NotificationTokenRefreshedEvent(this.token);

  final String token;
}

class NotificationForegroundMessageReceivedEvent extends NotificationEvent {
  const NotificationForegroundMessageReceivedEvent(this.notification);

  final PushNotification notification;
}

class NotificationOpenedEvent extends NotificationEvent {
  const NotificationOpenedEvent({
    required this.notification,
    required this.source,
  });

  final PushNotification notification;
  final String source;
}

class NotificationNavigationHandledEvent extends NotificationEvent {
  const NotificationNavigationHandledEvent();
}

/// El aviso de [NotificationState.infoMessage] ya se mostro.
class NotificationInfoMessageConsumedEvent extends NotificationEvent {
  const NotificationInfoMessageConsumedEvent();
}

class NotificationActiveDiscussionChangedEvent extends NotificationEvent {
  const NotificationActiveDiscussionChangedEvent({required this.discussionId});

  final String? discussionId;
}

/// La pantalla de [discussionId] dejo de estar visible.
///
/// Solo limpia la discussion activa si sigue siendo esa: una pantalla que se
/// descarta tarde (por ejemplo al reiniciar la pila) no borra la discussion
/// que ya abrio otra.
class NotificationActiveDiscussionClearedEvent extends NotificationEvent {
  const NotificationActiveDiscussionClearedEvent({required this.discussionId});

  final String discussionId;
}

class NotificationAppLifecycleResumedEvent extends NotificationEvent {
  const NotificationAppLifecycleResumedEvent();
}
