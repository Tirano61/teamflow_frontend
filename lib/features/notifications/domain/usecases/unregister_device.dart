import '../../../../core/error/result.dart';
import '../repositories/notification_device_repository.dart';

/// Desregistra este dispositivo de las notificaciones push del usuario
/// autenticado. Se usa al cerrar sesion, antes de borrar el JWT.
class UnregisterDevice {
  const UnregisterDevice(this._repository);

  final NotificationDeviceRepository _repository;

  Future<Result<void>> call() {
    return _repository.unregisterCurrentDevice();
  }
}
