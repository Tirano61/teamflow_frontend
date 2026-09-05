import '../../../../core/error/result.dart';
import '../entities/user_context.dart';

abstract class UserContextRepository {
  /// Contexto del usuario autenticado (`GET /me/context`).
  Future<Result<UserContext>> loadUserContext();
}
