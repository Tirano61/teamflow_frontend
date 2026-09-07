import '../../../../core/error/result.dart';
import '../entities/user_search_result.dart';

abstract class UserRepository {
  /// Busca usuarios registrados de TeamFlow (`GET /users/search`).
  ///
  /// La busqueda es global: no filtra por organizacion activa. El backend
  /// excluye al usuario autenticado y a los usuarios inactivos.
  /// El `limit` lo decide el caso de uso: el repositorio no inventa un valor
  /// por defecto propio.
  Future<Result<List<UserSearchResult>>> searchUsers({
    required String query,
    required int limit,
  });
}
