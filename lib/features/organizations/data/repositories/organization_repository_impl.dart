import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/security_verification.dart';
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

  @override
  Future<Result<RequestedSecurityVerification>>
  requestOrganizationDeletionCode() async {
    try {
      final model = await _remoteDataSource.requestOrganizationDeletionCode();
      return Success<RequestedSecurityVerification>(model.toEntity());
    } catch (error) {
      return FailureResult<RequestedSecurityVerification>(
        mapExceptionToFailure(error),
      );
    }
  }

  @override
  Future<Result<VerifiedSecurityVerification>> verifySecurityCode({
    required String verificationId,
    required String code,
  }) async {
    try {
      final model = await _remoteDataSource.verifySecurityCode(
        verificationId: verificationId,
        code: code,
      );
      return Success<VerifiedSecurityVerification>(model.toEntity());
    } catch (error) {
      return FailureResult<VerifiedSecurityVerification>(
        mapExceptionToFailure(error),
      );
    }
  }

  @override
  Future<Result<void>> deleteActiveOrganization() async {
    try {
      await _remoteDataSource.deleteActiveOrganization();
      return const Success<void>(null);
    } catch (error) {
      return FailureResult<void>(mapExceptionToFailure(error));
    }
  }
}
