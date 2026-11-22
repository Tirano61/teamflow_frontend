import '../../../../core/error/result.dart';
import '../repositories/notification_device_repository.dart';

/// Invalida en Firebase el token FCM de este dispositivo cuando el logout no
/// pudo desregistrarlo en el backend. No necesita JWT.
class RevokeDeviceToken {
  const RevokeDeviceToken(this._repository);

  final NotificationDeviceRepository _repository;

  Future<Result<void>> call() {
    return _repository.revokeCurrentToken();
  }
}
