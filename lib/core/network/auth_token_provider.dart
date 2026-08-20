enum AuthSessionSignalType { sessionRequired, sessionExpired }

class AuthSessionSignal {
  const AuthSessionSignal({required this.type, required this.message});

  final AuthSessionSignalType type;
  final String message;
}

abstract class AuthTokenProvider {
  Future<String?> getAccessToken();

  Future<void> clearAccessToken();

  bool get hasAccessToken;

  Stream<AuthSessionSignal> get sessionSignals;

  void notifySessionRequired([String message]);

  void notifySessionExpired([String message]);
}
