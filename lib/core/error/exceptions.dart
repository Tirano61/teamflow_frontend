class DataException implements Exception {
  const DataException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NetworkException extends DataException {
  const NetworkException(super.message);
}

class HttpStatusException extends DataException {
  const HttpStatusException({
    required this.statusCode,
    required String message,
    this.body,
  }) : super(message);

  final int statusCode;
  final String? body;
}

class DataParsingException extends DataException {
  const DataParsingException(super.message);
}

class ValidationException extends DataException {
  const ValidationException(super.message);
}

class SessionNotStartedException extends DataException {
  const SessionNotStartedException(super.message);
}

class UnauthorizedSessionException extends DataException {
  const UnauthorizedSessionException(super.message);
}

class PermissionDeniedException extends DataException {
  const PermissionDeniedException(super.message);
}
