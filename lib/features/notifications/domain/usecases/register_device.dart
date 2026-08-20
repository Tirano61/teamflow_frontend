import '../../../../core/error/result.dart';
import '../repositories/notification_device_repository.dart';

class RegisterDevice {
  const RegisterDevice(this._repository);

  final NotificationDeviceRepository _repository;

  Future<Result<void>> call(RegisterDeviceParams params) {
    return _repository.registerDevice(
      token: params.token,
      platform: params.platform,
    );
  }
}

class RegisterDeviceParams {
  const RegisterDeviceParams({required this.token, required this.platform});

  final String token;
  final NotificationDevicePlatform platform;
}
