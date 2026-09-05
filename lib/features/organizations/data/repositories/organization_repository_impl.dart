import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/organization_repository.dart';
import '../datasources/organization_remote_data_source.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  OrganizationRepositoryImpl({
    required OrganizationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final OrganizationRemoteDataSource _remoteDataSource;

  @override
  Future<Result<Organization>> createOrganization({
    required String name,
  }) async {
    try {
      final model = await _remoteDataSource.createOrganization(name: name);
      return Success<Organization>(model.toEntity());
    } catch (error) {
      return FailureResult<Organization>(mapExceptionToFailure(error));
    }
  }
}
