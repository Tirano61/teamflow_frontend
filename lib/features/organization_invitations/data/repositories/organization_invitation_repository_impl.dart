import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/organization_invitation_role.dart';
import '../../domain/repositories/organization_invitation_repository.dart';
import '../datasources/organization_invitation_remote_data_source.dart';

class OrganizationInvitationRepositoryImpl
    implements OrganizationInvitationRepository {
  OrganizationInvitationRepositoryImpl({
    required OrganizationInvitationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final OrganizationInvitationRemoteDataSource _remoteDataSource;

  @override
  Future<Result<void>> acceptInvitation({required String token}) async {
    try {
      await _remoteDataSource.acceptInvitation(token: token);
      return const Success<void>(null);
    } catch (error) {
      return FailureResult<void>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> createInvitation({
    required String userId,
    required OrganizationInvitationRole role,
  }) async {
    try {
      await _remoteDataSource.createInvitation(userId: userId, role: role);
      return const Success<void>(null);
    } catch (error) {
      return FailureResult<void>(mapExceptionToFailure(error));
    }
  }
}
