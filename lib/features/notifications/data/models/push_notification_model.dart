import '../../domain/entities/push_notification.dart';

/// Lectura de `RemoteMessage.data` segun el contrato de push del backend
/// (`type`, `recipientUserId`, `organizationId`, `discussionId`).
class PushNotificationModel extends PushNotification {
  const PushNotificationModel({
    required super.type,
    super.recipientUserId,
    super.organizationId,
    super.discussionId,
  });

  factory PushNotificationModel.fromData(Map<String, dynamic> data) {
    return PushNotificationModel(
      type: _readString(data['type']) ?? '',
      recipientUserId: _readUuid(data['recipientUserId']),
      organizationId: _readUuid(data['organizationId']),
      discussionId: _readUuid(data['discussionId']),
    );
  }

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static String? _readString(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Los ids del backend son UUID: cualquier otro valor se descarta en lugar
  /// de llegar a una ruta o a una URL.
  static String? _readUuid(Object? value) {
    final text = _readString(value);
    if (text == null || !_uuidPattern.hasMatch(text)) {
      return null;
    }

    return text;
  }
}
