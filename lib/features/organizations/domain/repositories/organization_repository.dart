import '../../../../core/error/result.dart';
import '../entities/organization.dart';
import '../entities/security_verification.dart';

abstract class OrganizationRepository {
  /// Crea una organizacion (`POST /organizations`).
  ///
  /// El usuario autenticado queda como `OWNER` de la organizacion creada.
  Future<Result<Organization>> createOrganization({required String name});

  /// Pide el codigo de seguridad para eliminar la organizacion activa
  /// (`POST .../security-verifications` con purpose `DELETE_ORGANIZATION`).
  ///
  /// Invalida en el backend cualquier codigo o autorizacion anterior del mismo
  /// usuario + organizacion + purpose.
  Future<Result<RequestedSecurityVerification>>
  requestOrganizationDeletionCode();

  /// Verifica el codigo de la verificacion [verificationId] de la
  /// organizacion activa (`POST .../security-verifications/{id}/verify`).
  ///
  /// No elimina nada: solo deja la autorizacion `VERIFIED` en el backend.
  Future<Result<VerifiedSecurityVerification>> verifySecurityCode({
    required String verificationId,
    required String code,
  });

  /// Elimina definitivamente la organizacion activa
  /// (`DELETE /organizations/{organizationId}`).
  ///
  /// La lista de organizaciones no se corrige aca: quien llama debe recargar
  /// `/me/context`, que es la fuente de verdad de la pertenencia.
  Future<Result<void>> deleteActiveOrganization();
}
