import '../../../../core/error/result.dart';
import '../entities/security_verification.dart';
import '../repositories/organization_repository.dart';

class RequestOrganizationDeletionCode {
  const RequestOrganizationDeletionCode(this._repository);

  final OrganizationRepository _repository;

  /// Pide el codigo `DELETE_ORGANIZATION` de la organizacion activa.
  ///
  /// No recibe `organizationId`: el datasource lo resuelve contra
  /// `OrganizationContext` en el momento del request.
  Future<Result<RequestedSecurityVerification>> call() {
    return _repository.requestOrganizationDeletionCode();
  }
}
