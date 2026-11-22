import 'package:shared_preferences/shared_preferences.dart';

/// Estado local de notificaciones que tiene que sobrevivir a un reinicio.
///
/// Solo guarda una marca: nunca el token FCM ni datos del usuario.
abstract class NotificationLocalDataSource {
  /// Un logout no pudo desregistrar el token en el backend y la revocacion en
  /// Firebase (`deleteToken`) todavia no se confirmo.
  bool get isTokenRevocationPending;

  Future<void> markTokenRevocationPending();

  Future<void> clearTokenRevocationPending();
}

class SharedPreferencesNotificationLocalDataSource
    implements NotificationLocalDataSource {
  const SharedPreferencesNotificationLocalDataSource({
    required SharedPreferences sharedPreferences,
  }) : _sharedPreferences = sharedPreferences;

  static const String _tokenRevocationPendingKey =
      'fcm_token_revocation_pending';

  final SharedPreferences _sharedPreferences;

  @override
  bool get isTokenRevocationPending =>
      _sharedPreferences.getBool(_tokenRevocationPendingKey) ?? false;

  @override
  Future<void> markTokenRevocationPending() async {
    await _sharedPreferences.setBool(_tokenRevocationPendingKey, true);
  }

  @override
  Future<void> clearTokenRevocationPending() async {
    await _sharedPreferences.remove(_tokenRevocationPendingKey);
  }
}
