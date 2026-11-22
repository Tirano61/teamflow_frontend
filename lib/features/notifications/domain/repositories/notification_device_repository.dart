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

  /// Invalida el token FCM de este dispositivo en Firebase (`deleteToken`),
  /// sin pasar por el backend ni usar JWT.
  ///
  /// Se usa cuando el logout no pudo desregistrar el token: el backend sigue
  /// enviando los push del usuario anterior a ese token hasta que Firebase lo
  /// rechace y lo elimine. Deja la revocacion marcada como pendiente hasta
  /// confirmarla, para reintentarla si ahora no hay conexion.
  Future<Result<void>> revokeCurrentToken();

  /// Reintenta la revocacion pendiente, si la hay. Devuelve `true` si el
  /// token se revoco en esta llamada (el token conocido ya no sirve).
  Future<bool> reconcilePendingTokenRevocation();
}
