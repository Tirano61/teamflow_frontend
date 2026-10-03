/// Operacion sensible que confirma una SecurityVerification.
///
/// Por ahora el backend solo define `DELETE_ORGANIZATION`.
enum SecurityVerificationPurpose {
  deleteOrganization('DELETE_ORGANIZATION');

  const SecurityVerificationPurpose(this.apiValue);

  /// Valor exacto que usa el backend en el body y en las responses.
  final String apiValue;

  /// El purpose equivalente a [value], o `null` si este frontend no lo
  /// conoce.
  static SecurityVerificationPurpose? fromApiValue(String value) {
    final normalized = value.trim().toUpperCase();

    for (final purpose in values) {
      if (purpose.apiValue == normalized) {
        return purpose;
      }
    }

    return null;
  }
}

/// Codigo de seguridad solicitado
/// (`POST /organizations/{organizationId}/security-verifications`).
///
/// Solo metadata: el backend nunca devuelve el codigo, su hash ni los intentos.
class RequestedSecurityVerification {
  const RequestedSecurityVerification({
    required this.verificationId,
    required this.purpose,
    required this.expiresAt,
    required this.resendAvailableAt,
  });

  final String verificationId;
  final SecurityVerificationPurpose purpose;

  /// Vencimiento del codigo enviado por email.
  final DateTime expiresAt;

  /// A partir de cuando el backend acepta pedir otro codigo.
  final DateTime resendAvailableAt;
}

/// Codigo verificado
/// (`POST .../security-verifications/{verificationId}/verify`).
///
/// La autorizacion queda del lado del backend; el cliente no la envia en la
/// operacion sensible y no decide localmente si sigue vigente.
class VerifiedSecurityVerification {
  const VerifiedSecurityVerification({
    required this.verificationId,
    required this.purpose,
    required this.verifiedAt,
    required this.authorizationExpiresAt,
  });

  final String verificationId;
  final SecurityVerificationPurpose purpose;
  final DateTime verifiedAt;

  /// Hasta cuando el backend acepta consumir la autorizacion.
  final DateTime authorizationExpiresAt;
}
