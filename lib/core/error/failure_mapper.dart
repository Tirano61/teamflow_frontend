import '../organization/organization_context.dart';
import 'exceptions.dart';
import 'failure.dart';

Failure mapExceptionToFailure(Object error) {
  if (error is Failure) {
    return error;
  }

  // Debe evaluarse antes que ValidationException/DataException: es una
  // subclase de DataException con un significado propio para la app.
  if (error is OrganizationNotSelectedException) {
    return OrganizationRequiredFailure(error.message);
  }

  if (error is ValidationException) {
    return ValidationFailure(error.message);
  }

  if (error is SessionNotStartedException) {
    return SessionRequiredFailure(error.message);
  }

  if (error is UnauthorizedSessionException) {
    return UnauthorizedFailure(error.message);
  }

  if (error is PermissionDeniedException) {
    return PermissionDeniedFailure(error.message);
  }

  if (error is NetworkException) {
    return NetworkFailure(error.message);
  }

  if (error is HttpStatusException) {
    if (error.statusCode == 401) {
      return UnauthorizedFailure(error.message);
    }

    if (error.statusCode == 403) {
      return PermissionDeniedFailure(error.message);
    }

    return ServerFailure(statusCode: error.statusCode, message: error.message);
  }

  if (error is DataParsingException) {
    return ParsingFailure(error.message);
  }

  return UnknownFailure(error.toString());
}
