import '../../domain/entities/security_verification.dart';

/// Paso del flujo de eliminacion de la organizacion activa.
enum OrganizationDeletionStatus {
  /// Sin codigo pedido. Es el paso de confirmacion por nombre.
  idle,

  /// `POST .../security-verifications` en curso (primera solicitud o
  /// reenvio).
  requestingCode,

  /// Hay un codigo enviado y se espera que el usuario lo ingrese.
  awaitingCode,

  /// `POST .../verify` en curso.
  verifyingCode,

  /// Codigo verificado: falta la confirmacion final. Nada se elimino.
  verified,

  /// `DELETE /organizations/{organizationId}` en curso.
  deleting,

  /// El backend respondio 204. Falta que `/me/context` lo refleje.
  deleted,

  /// El flujo termino sin una eliminacion confirmada (403 en cualquier paso o
  /// resultado del `DELETE` no confirmado). Permisos u organizacion pudieron
  /// cambiar: hay que recargar `/me/context`.
  aborted,
}

class OrganizationDeletionState {
  const OrganizationDeletionState({
    this.status = OrganizationDeletionStatus.idle,
    this.verification,
    this.authorization,
    this.isVerificationClosed = false,
    this.canResend = false,
    this.requestErrorMessage = '',
    this.verifyErrorMessage = '',
    this.deleteErrorMessage = '',
    this.isDeleteResultUnknown = false,
  });

  final OrganizationDeletionStatus status;

  /// Unica verificacion vigente. Un codigo nuevo la reemplaza: nunca hay dos.
  final RequestedSecurityVerification? verification;

  /// Respuesta de la verificacion correcta. Es informativa: si la autorizacion
  /// sigue vigente lo decide el backend al recibir el `DELETE`.
  final VerifiedSecurityVerification? authorization;

  /// El backend indico que [verification] ya no se puede verificar (404, 409
  /// o 429): solo queda pedir un codigo nuevo.
  final bool isVerificationClosed;

  /// Ya paso `resendAvailableAt` de [verification].
  final bool canResend;

  /// Error de la ultima solicitud de codigo.
  final String requestErrorMessage;

  /// Error de la ultima verificacion de codigo.
  final String verifyErrorMessage;

  /// Error del ultimo `DELETE`.
  final String deleteErrorMessage;

  /// El `DELETE` se envio pero no se pudo confirmar su resultado (red,
  /// timeout o respuesta inesperada): la organizacion pudo haberse eliminado.
  final bool isDeleteResultUnknown;

  /// Hay un request en curso: bloquea el doble submit y el cierre del flujo.
  bool get isBusy =>
      status == OrganizationDeletionStatus.requestingCode ||
      status == OrganizationDeletionStatus.verifyingCode ||
      status == OrganizationDeletionStatus.deleting;

  /// El flujo se puede cerrar sin dejar un request a medias ni ocultar el
  /// resultado de la eliminacion.
  bool get canCancel => !isBusy && status != OrganizationDeletionStatus.deleted;

  /// Se puede enviar el codigo de la verificacion vigente.
  bool get canSubmitCode =>
      status == OrganizationDeletionStatus.awaitingCode &&
      verification != null &&
      !isVerificationClosed;

  /// Mensaje del paso que termino el flujo, si termino en [aborted].
  String get abortMessage {
    for (final message in [
      deleteErrorMessage,
      verifyErrorMessage,
      requestErrorMessage,
    ]) {
      if (message.trim().isNotEmpty) {
        return message;
      }
    }

    return '';
  }

  OrganizationDeletionState copyWith({
    OrganizationDeletionStatus? status,
    RequestedSecurityVerification? verification,
    bool clearVerification = false,
    VerifiedSecurityVerification? authorization,
    bool clearAuthorization = false,
    bool? isVerificationClosed,
    bool? canResend,
    String? requestErrorMessage,
    String? verifyErrorMessage,
    String? deleteErrorMessage,
    bool? isDeleteResultUnknown,
  }) {
    return OrganizationDeletionState(
      status: status ?? this.status,
      verification: clearVerification
          ? null
          : verification ?? this.verification,
      authorization: clearAuthorization
          ? null
          : authorization ?? this.authorization,
      isVerificationClosed: isVerificationClosed ?? this.isVerificationClosed,
      canResend: canResend ?? this.canResend,
      requestErrorMessage: requestErrorMessage ?? this.requestErrorMessage,
      verifyErrorMessage: verifyErrorMessage ?? this.verifyErrorMessage,
      deleteErrorMessage: deleteErrorMessage ?? this.deleteErrorMessage,
      isDeleteResultUnknown:
          isDeleteResultUnknown ?? this.isDeleteResultUnknown,
    );
  }
}
