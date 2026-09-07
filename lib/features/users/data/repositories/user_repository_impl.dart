import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/user_search_result.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({required UserRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final UserRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<UserSearchResult>>> searchUsers({
    required String query,
    required int limit,
  }) async {
    try {
      final models = await _remoteDataSource.searchUsers(
        query: query,
        limit: limit,
      );

      return Success<List<UserSearchResult>>(
        models.map((model) => model.toEntity()).toList(growable: false),
      );
    } catch (error) {
      return FailureResult<List<UserSearchResult>>(
        mapExceptionToFailure(error),
      );
    }
  }
}
