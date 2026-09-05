import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/user_context.dart';
import '../../domain/repositories/user_context_repository.dart';
import '../datasources/user_context_remote_data_source.dart';

class UserContextRepositoryImpl implements UserContextRepository {
  UserContextRepositoryImpl({
    required UserContextRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final UserContextRemoteDataSource _remoteDataSource;

  @override
  Future<Result<UserContext>> loadUserContext() async {
    try {
      final model = await _remoteDataSource.getUserContext();
      return Success<UserContext>(model.toEntity());
    } catch (error) {
      return FailureResult<UserContext>(mapExceptionToFailure(error));
    }
  }
}
