import 'package:firebase_messaging/firebase_messaging.dart';

abstract class FirebaseMessagingDataSource {
  bool get isSupported;

  Future<void> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<Map<String, String>> get onMessage;

  Stream<Map<String, String>> get onMessageOpenedApp;

  Future<Map<String, String>?> getInitialMessage();
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
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<Map<String, String>> get onMessage => FirebaseMessaging.onMessage.map(
    (message) => _normalizeData(message.data),
  );

  @override
  Stream<Map<String, String>> get onMessageOpenedApp => FirebaseMessaging
      .onMessageOpenedApp
      .map((message) => _normalizeData(message.data));

  @override
  Future<Map<String, String>?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) {
      return null;
    }

    return _normalizeData(message.data);
  }

  Map<String, String> _normalizeData(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, value.toString()));
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
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Stream<Map<String, String>> get onMessage =>
      const Stream<Map<String, String>>.empty();

  @override
  Stream<Map<String, String>> get onMessageOpenedApp =>
      const Stream<Map<String, String>>.empty();

  @override
  Future<Map<String, String>?> getInitialMessage() async => null;
}
