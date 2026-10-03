sealed class OrganizationDeletionEvent {
  const OrganizationDeletionEvent();
}

/// El usuario pide el codigo de seguridad.
///
/// Sirve para la primera solicitud (despues de confirmar el nombre) y para
/// `Enviar un nuevo codigo`: un codigo nuevo reemplaza al anterior.
class OrganizationDeletionCodeRequested extends OrganizationDeletionEvent {
  const OrganizationDeletionCodeRequested();
}

/// El usuario envia el codigo de 6 digitos recibido por email.
///
/// El `verificationId` no viaja en el evento: es el de la verificacion vigente
/// del estado, la unica que el bloc conserva.
class OrganizationDeletionCodeSubmitted extends OrganizationDeletionEvent {
  const OrganizationDeletionCodeSubmitted(this.code);

  final String code;
}

/// El usuario confirma `Eliminar definitivamente` despues de verificar.
class OrganizationDeletionConfirmed extends OrganizationDeletionEvent {
  const OrganizationDeletionConfirmed();
}

/// El usuario cierra el flujo antes del `DELETE`.
///
/// No llama al backend: una autorizacion ya verificada queda vigente hasta
/// vencer y la invalida el backend si se pide otro codigo.
class OrganizationDeletionCancelled extends OrganizationDeletionEvent {
  const OrganizationDeletionCancelled();
}

/// Uso interno del bloc: llego `resendAvailableAt` de la verificacion vigente.
class OrganizationDeletionResendAvailable extends OrganizationDeletionEvent {
  const OrganizationDeletionResendAvailable(this.verificationId);

  final String verificationId;
}
