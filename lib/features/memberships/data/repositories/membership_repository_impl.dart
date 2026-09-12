import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/membership_role.dart';
import '../../domain/repositories/membership_repository.dart';
import '../datasources/membership_remote_data_source.dart';

class MembershipRepositoryImpl implements MembershipRepository {
  MembershipRepositoryImpl({
    required MembershipRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final MembershipRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Membership>>> getOrganizationMembers() async {
    try {
      final models = await _remoteDataSource.getOrganizationMembers();
      return Success<List<Membership>>(
        models.map((model) => model.toEntity()).toList(growable: false),
      );
    } catch (error) {
      return FailureResult<List<Membership>>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Membership>> changeMemberRole({
    required String membershipId,
    required MembershipRole role,
  }) async {
    try {
      final model = await _remoteDataSource.changeMemberRole(
        membershipId: membershipId,
        role: role,
      );

      return Success<Membership>(model.toEntity());
    } catch (error) {
      return FailureResult<Membership>(mapExceptionToFailure(error));
    }
  }
}
