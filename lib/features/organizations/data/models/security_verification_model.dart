import '../../../../core/error/exceptions.dart';
import '../../domain/entities/security_verification.dart';

/// Response de `POST /organizations/{organizationId}/security-verifications`.
///
/// Contrato real (`SecurityVerificationRequestedResponse`):
/// `verificationId`, `purpose`, `expiresAt`, `resendAvailableAt`.
class RequestedSecurityVerificationModel {
  const RequestedSecurityVerificationModel({
    required this.verificationId,
    required this.purpose,
    required this.expiresAt,
    required this.resendAvailableAt,
  });

  final String verificationId;
  final SecurityVerificationPurpose purpose;
  final DateTime expiresAt;
  final DateTime resendAvailableAt;

  factory RequestedSecurityVerificationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return RequestedSecurityVerificationModel(
      verificationId: _requireString(json, 'verificationId'),
      purpose: _requirePurpose(json),
      expiresAt: _requireDate(json, 'expiresAt'),
      resendAvailableAt: _requireDate(json, 'resendAvailableAt'),
    );
  }

  RequestedSecurityVerification toEntity() {
    return RequestedSecurityVerification(
      verificationId: verificationId,
      purpose: purpose,
      expiresAt: expiresAt,
      resendAvailableAt: resendAvailableAt,
    );
  }
}

/// Response de
/// `POST /organizations/{organizationId}/security-verifications/{verificationId}/verify`.
///
/// Contrato real (`SecurityVerificationVerifiedResponse`):
/// `verificationId`, `purpose`, `verifiedAt`, `authorizationExpiresAt`.
class VerifiedSecurityVerificationModel {
  const VerifiedSecurityVerificationModel({
    required this.verificationId,
    required this.purpose,
    required this.verifiedAt,
    required this.authorizationExpiresAt,
  });

  final String verificationId;
  final SecurityVerificationPurpose purpose;
  final DateTime verifiedAt;
  final DateTime authorizationExpiresAt;

  factory VerifiedSecurityVerificationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return VerifiedSecurityVerificationModel(
      verificationId: _requireString(json, 'verificationId'),
      purpose: _requirePurpose(json),
      verifiedAt: _requireDate(json, 'verifiedAt'),
      authorizationExpiresAt: _requireDate(json, 'authorizationExpiresAt'),
    );
  }

  VerifiedSecurityVerification toEntity() {
    return VerifiedSecurityVerification(
      verificationId: verificationId,
      purpose: purpose,
      verifiedAt: verifiedAt,
      authorizationExpiresAt: authorizationExpiresAt,
    );
  }
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  final parsed = value is String ? value.trim() : '';
  if (parsed.isEmpty) {
    throw DataParsingException(
      'La verificacion de seguridad no incluye un `$key` valido.',
    );
  }

  return parsed;
}

SecurityVerificationPurpose _requirePurpose(Map<String, dynamic> json) {
  final purpose = SecurityVerificationPurpose.fromApiValue(
    _requireString(json, 'purpose'),
  );
  if (purpose == null) {
    throw const DataParsingException(
      'La verificacion de seguridad tiene un proposito desconocido.',
    );
  }

  return purpose;
}

DateTime _requireDate(Map<String, dynamic> json, String key) {
  final parsed = DateTime.tryParse(_requireString(json, key));
  if (parsed == null) {
    throw DataParsingException(
      'La verificacion de seguridad no incluye una fecha `$key` valida.',
    );
  }

  return parsed;
}
