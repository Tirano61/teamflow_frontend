import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/notification_device_repository.dart';
import '../datasources/notification_device_remote_data_source.dart';

class NotificationDeviceRepositoryImpl implements NotificationDeviceRepository {
  NotificationDeviceRepositoryImpl({
    required NotificationDeviceRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final NotificationDeviceRemoteDataSource _remoteDataSource;

  @override
  Future<Result<void>> registerDevice({
    required String token,
    required NotificationDevicePlatform platform,
  }) async {
    try {
      await _remoteDataSource.registerDevice(
        token: token,
        platform: platform.apiValue,
      );
      return const Success<void>(null);
    } catch (error) {
      return FailureResult<void>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> unregisterDevice({required String token}) async {
    try {
      await _remoteDataSource.unregisterDevice(token: token);
      return const Success<void>(null);
    } catch (error) {
      return FailureResult<void>(mapExceptionToFailure(error));
    }
  }
}
