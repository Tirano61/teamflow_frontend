import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/auth_token_provider.dart';
import '../models/auth_session_model.dart';

abstract class AuthLocalDataSource {
  Future<void> initialize();

  Future<void> saveSession(AuthSessionModel session);

  Future<AuthSessionModel?> getStoredSession();

  Future<void> clearSession();
}

class AuthLocalDataSourceImpl
    implements AuthLocalDataSource, AuthTokenProvider {
  AuthLocalDataSourceImpl({required SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  static const String _sessionStorageKey = 'auth_session_json';

  final SharedPreferences _sharedPreferences;
  final StreamController<AuthSessionSignal> _sessionSignalsController =
      StreamController<AuthSessionSignal>.broadcast();

  AuthSessionModel? _cachedSession;

  @override
  Future<void> initialize() async {
    final raw = _sharedPreferences.getString(_sessionStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      _cachedSession = null;
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _cachedSession = AuthSessionModel.fromStorageJson(decoded);
      } else {
        _cachedSession = null;
        await _sharedPreferences.remove(_sessionStorageKey);
      }
    } catch (_) {
      _cachedSession = null;
      await _sharedPreferences.remove(_sessionStorageKey);
    }
  }

  @override
  Future<void> saveSession(AuthSessionModel session) async {
    _cachedSession = session;
    final payload = jsonEncode(session.toStorageJson());
    await _sharedPreferences.setString(_sessionStorageKey, payload);
  }

  @override
  Future<AuthSessionModel?> getStoredSession() async {
    return _cachedSession;
  }

  @override
  Future<void> clearSession() async {
    _cachedSession = null;
    await _sharedPreferences.remove(_sessionStorageKey);
  }

  @override
  Future<String?> getAccessToken() async {
    return _cachedSession?.token;
  }

  @override
  bool get hasAccessToken {
    final token = _cachedSession?.token;
    return token != null && token.trim().isNotEmpty;
  }

  @override
  Stream<AuthSessionSignal> get sessionSignals =>
      _sessionSignalsController.stream;

  @override
  void notifySessionRequired([
    String message = 'Sesion no iniciada. Inicia sesion para continuar.',
  ]) {
    _sessionSignalsController.add(
      AuthSessionSignal(
        type: AuthSessionSignalType.sessionRequired,
        message: message,
      ),
    );
  }

  @override
  void notifySessionExpired([
    String message =
        'Tu sesion expiro o no es valida. Inicia sesion nuevamente.',
  ]) {
    _sessionSignalsController.add(
      AuthSessionSignal(
        type: AuthSessionSignalType.sessionExpired,
        message: message,
      ),
    );
  }

  @override
  Future<void> clearAccessToken() {
    return clearSession();
  }
}
