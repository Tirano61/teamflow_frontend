import '../../../../core/error/result.dart';
import '../entities/user_search_result.dart';
import '../repositories/user_repository.dart';

class SearchUsers {
  const SearchUsers(this._repository);

  final UserRepository _repository;

  /// Limite por defecto de la busqueda, alineado con el `limit=10` que espera
  /// el backend.
  static const int defaultLimit = 10;

  Future<Result<List<UserSearchResult>>> call({
    required String query,
    int limit = defaultLimit,
  }) {
    return _repository.searchUsers(query: query, limit: limit);
  }
}
