import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../models/device_registration_request_model.dart';
import '../models/device_unregistration_request_model.dart';

abstract class NotificationDeviceRemoteDataSource {
  Future<void> registerDevice({
    required String token,
    required String platform,
  });

  Future<void> unregisterDevice({required String token});
}

class NotificationDeviceRemoteDataSourceImpl
    implements NotificationDeviceRemoteDataSource {
  NotificationDeviceRemoteDataSourceImpl({required RestClient restClient})
    : _restClient = restClient;

  final RestClient _restClient;

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    final normalizedToken = token.trim();
    final normalizedPlatform = platform.trim().toUpperCase();

    if (normalizedToken.isEmpty || normalizedPlatform.isEmpty) {
      throw const ValidationException(
        'Token y plataforma son obligatorios para registrar dispositivo.',
      );
    }

    final payload = DeviceRegistrationRequestModel(
      token: normalizedToken,
      platform: normalizedPlatform,
    );

    await _restClient.post<Object?>(
      ApiEndpoints.devices,
      body: payload.toJson(),
    );
  }

  @override
  Future<void> unregisterDevice({required String token}) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw const ValidationException(
        'El token es obligatorio para desregistrar dispositivo.',
      );
    }

    final payload = DeviceUnregistrationRequestModel(token: normalizedToken);

    await _restClient.delete<Object?>(
      ApiEndpoints.devices,
      body: payload.toJson(),
    );
  }
}
