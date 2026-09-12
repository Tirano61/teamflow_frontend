import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/membership_role.dart';
import '../../domain/repositories/membership_repository.dart';
import '../datasources/membership_remote_data_source.dart';
import '../models/membership_model.dart';

class MembershipRepositoryImpl implements MembershipRepository {
  MembershipRepositoryImpl({
    required MembershipRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final MembershipRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Membership>>> getOrganizationMembers() {
    return _members(_remoteDataSource.getOrganizationMembers);
  }

  @override
  Future<Result<List<Membership>>> getOrganizationMembersForManagement() {
    return _members(_remoteDataSource.getOrganizationMembersForManagement);
  }

  @override
  Future<Result<Membership>> changeMemberRole({
    required String membershipId,
    required MembershipRole role,
  }) {
    return _member(
      () => _remoteDataSource.changeMemberRole(
        membershipId: membershipId,
        role: role,
      ),
    );
  }

  @override
  Future<Result<Membership>> suspendMember({required String membershipId}) {
    return _member(
      () => _remoteDataSource.suspendMember(membershipId: membershipId),
    );
  }

  @override
  Future<Result<Membership>> reactivateMember({required String membershipId}) {
    return _member(
      () => _remoteDataSource.reactivateMember(membershipId: membershipId),
    );
  }

  /// Listado + mapeo de excepciones a la jerarquia de Failure del proyecto.
  ///
  /// El directorio y la administracion comparten contrato de respuesta: solo
  /// cambia el endpoint que llama el datasource.
  Future<Result<List<Membership>>> _members(
    Future<List<MembershipModel>> Function() request,
  ) async {
    try {
      final models = await request();
      return Success<List<Membership>>(
        models.map((model) => model.toEntity()).toList(growable: false),
      );
    } catch (error) {
      return FailureResult<List<Membership>>(mapExceptionToFailure(error));
    }
  }

  /// Una sola membresia: cambio de rol, suspension y reactivacion devuelven la
  /// fila ya actualizada con el mismo contrato.
  Future<Result<Membership>> _member(
    Future<MembershipModel> Function() request,
  ) async {
    try {
      final model = await request();
      return Success<Membership>(model.toEntity());
    } catch (error) {
      return FailureResult<Membership>(mapExceptionToFailure(error));
    }
  }
}
