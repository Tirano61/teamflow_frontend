import '../../../../core/error/result.dart';

enum NotificationDevicePlatform { android }

extension NotificationDevicePlatformApi on NotificationDevicePlatform {
  String get apiValue {
    switch (this) {
      case NotificationDevicePlatform.android:
        return 'ANDROID';
    }
  }
}

abstract class NotificationDeviceRepository {
  Future<Result<void>> registerDevice({
    required String token,
    required NotificationDevicePlatform platform,
  });

  /// Desregistra el token FCM actual de este dispositivo para el usuario
  /// autenticado (`DELETE /workspace/devices`).
  ///
  /// Necesita el JWT todavia vigente: se invoca antes de cerrar la sesion
  /// local. Termina en `Success` si no hay nada que desregistrar (plataforma
  /// sin push, sin token) o si el backend ya no lo tenia asociado al usuario.
  Future<Result<void>> unregisterCurrentDevice();
}
