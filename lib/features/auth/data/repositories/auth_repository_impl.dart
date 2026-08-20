import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      await _localDataSource.saveSession(session);
      return Success<AuthSession>(session.toEntity());
    } catch (error) {
      return FailureResult<AuthSession>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<AuthSession?>> restoreSession() async {
    try {
      final session = await _localDataSource.getStoredSession();
      return Success<AuthSession?>(session?.toEntity());
    } catch (error) {
      return FailureResult<AuthSession?>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _localDataSource.clearSession();
      return const Success<void>(null);
    } catch (error) {
      return FailureResult<void>(mapExceptionToFailure(error));
    }
  }
}
