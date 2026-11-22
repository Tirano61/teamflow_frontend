import 'package:firebase_messaging/firebase_messaging.dart';

import '../../domain/entities/push_notification.dart';
import '../models/push_notification_model.dart';

abstract class FirebaseMessagingDataSource {
  bool get isSupported;

  Future<void> requestPermission();

  Future<String?> getToken();

  /// Invalida el token actual en Firebase. El proximo `getToken` genera uno
  /// nuevo (y se emite por [onTokenRefresh]). Necesita conexion.
  Future<void> deleteToken();

  Stream<String> get onTokenRefresh;

  Stream<PushNotification> get onMessage;

  Stream<PushNotification> get onMessageOpenedApp;

  Future<PushNotification?> getInitialMessage();
}

class FirebaseMessagingDataSourceImpl implements FirebaseMessagingDataSource {
  FirebaseMessagingDataSourceImpl({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  bool get isSupported => true;

  @override
  Future<void> requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  @override
  Future<String?> getToken() {
    return _messaging.getToken();
  }

  @override
  Future<void> deleteToken() {
    return _messaging.deleteToken();
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushNotification> get onMessage => FirebaseMessaging.onMessage.map(
    (message) => PushNotificationModel.fromData(message.data),
  );

  @override
  Stream<PushNotification> get onMessageOpenedApp => FirebaseMessaging
      .onMessageOpenedApp
      .map((message) => PushNotificationModel.fromData(message.data));

  @override
  Future<PushNotification?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) {
      return null;
    }

    return PushNotificationModel.fromData(message.data);
  }
}

class FirebaseMessagingNoOpDataSource implements FirebaseMessagingDataSource {
  const FirebaseMessagingNoOpDataSource();

  @override
  bool get isSupported => false;

  @override
  Future<void> requestPermission() async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Stream<PushNotification> get onMessage =>
      const Stream<PushNotification>.empty();

  @override
  Stream<PushNotification> get onMessageOpenedApp =>
      const Stream<PushNotification>.empty();

  @override
  Future<PushNotification?> getInitialMessage() async => null;
}
