import '../../../../core/error/result.dart';
import '../entities/membership.dart';
import '../repositories/membership_repository.dart';

class GetOrganizationMembers {
  const GetOrganizationMembers(this._repository);

  final MembershipRepository _repository;

  Future<Result<List<Membership>>> call() {
    return _repository.getOrganizationMembers();
  }
}
