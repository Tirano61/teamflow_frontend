import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/notification_device_repository.dart';
import '../datasources/firebase_messaging_data_source.dart';
import '../datasources/notification_device_remote_data_source.dart';

class NotificationDeviceRepositoryImpl implements NotificationDeviceRepository {
  NotificationDeviceRepositoryImpl({
    required NotificationDeviceRemoteDataSource remoteDataSource,
    required FirebaseMessagingDataSource messagingDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _messagingDataSource = messagingDataSource;

  final NotificationDeviceRemoteDataSource _remoteDataSource;
  final FirebaseMessagingDataSource _messagingDataSource;

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
  Future<Result<void>> unregisterCurrentDevice() async {
    if (!_messagingDataSource.isSupported) {
      return const Success<void>(null);
    }

    try {
      // El SDK devuelve el token que tiene cacheado: es el mismo que se
      // registro al autenticar, aunque esta ejecucion no lo haya registrado.
      final token = (await _messagingDataSource.getToken())?.trim();
      if (token == null || token.isEmpty) {
        return const Success<void>(null);
      }

      await _remoteDataSource.unregisterDevice(token: token);
      return const Success<void>(null);
    } on HttpStatusException catch (error) {
      // `Device token not found for current user`: el token ya no esta
      // asociado a este usuario, que es justo el resultado buscado.
      if (error.statusCode == 404) {
        return const Success<void>(null);
      }

      return FailureResult<void>(mapExceptionToFailure(error));
    } catch (error) {
      return FailureResult<void>(mapExceptionToFailure(error));
    }
  }
}
