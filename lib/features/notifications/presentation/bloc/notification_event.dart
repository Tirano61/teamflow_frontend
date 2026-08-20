sealed class NotificationEvent {
  const NotificationEvent();
}

class InitializeNotificationsEvent extends NotificationEvent {
  const InitializeNotificationsEvent();
}

class NotificationAuthStateChangedEvent extends NotificationEvent {
  const NotificationAuthStateChangedEvent({required this.isAuthenticated});

  final bool isAuthenticated;
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
