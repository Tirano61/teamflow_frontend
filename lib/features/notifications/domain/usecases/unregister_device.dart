import '../../../../core/error/result.dart';
import '../repositories/notification_device_repository.dart';

class UnregisterDevice {
  const UnregisterDevice(this._repository);

  final NotificationDeviceRepository _repository;

  Future<Result<void>> call(UnregisterDeviceParams params) {
    return _repository.unregisterDevice(token: params.token);
  }
}

class UnregisterDeviceParams {
  const UnregisterDeviceParams({required this.token});

  final String token;
}
