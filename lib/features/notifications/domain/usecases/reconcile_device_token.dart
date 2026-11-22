import '../repositories/notification_device_repository.dart';

/// Reintenta una revocacion del token FCM que quedo pendiente tras un logout
/// sin conexion. Devuelve `true` si el token se revoco en esta llamada.
class ReconcileDeviceToken {
  const ReconcileDeviceToken(this._repository);

  final NotificationDeviceRepository _repository;

  Future<bool> call() {
    return _repository.reconcilePendingTokenRevocation();
  }
}
