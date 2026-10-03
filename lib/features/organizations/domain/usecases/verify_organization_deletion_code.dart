import '../../../../core/error/result.dart';
import '../entities/security_verification.dart';
import '../repositories/organization_repository.dart';

class VerifyOrganizationDeletionCode {
  const VerifyOrganizationDeletionCode(this._repository);

  final OrganizationRepository _repository;

  /// Verifica el [code] recibido por email para [verificationId].
  ///
  /// Verificar no elimina la organizacion: la eliminacion es un paso aparte
  /// que el usuario confirma explicitamente.
  Future<Result<VerifiedSecurityVerification>> call({
    required String verificationId,
    required String code,
  }) {
    return _repository.verifySecurityCode(
      verificationId: verificationId,
      code: code,
    );
  }
}
