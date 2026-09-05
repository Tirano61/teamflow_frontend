import '../../../../core/error/result.dart';
import '../entities/organization.dart';
import '../repositories/organization_repository.dart';

class CreateOrganization {
  const CreateOrganization(this._repository);

  final OrganizationRepository _repository;

  Future<Result<Organization>> call({required String name}) {
    return _repository.createOrganization(name: name);
  }
}
