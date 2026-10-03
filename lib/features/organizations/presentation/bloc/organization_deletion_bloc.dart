import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/security_verification.dart';
import '../../domain/usecases/delete_organization.dart';
import '../../domain/usecases/request_organization_deletion_code.dart';
import '../../domain/usecases/verify_organization_deletion_code.dart';
import 'organization_deletion_event.dart';
import 'organization_deletion_state.dart';

/// Eliminacion segura de la organizacion activa.
///
/// Recorre codigo por email -> verificacion -> confirmacion final -> `DELETE`.
/// Cada paso espera una accion explicita del usuario: verificar nunca elimina.
///
/// No conoce ningun `organizationId` (lo resuelve el datasource contra
/// `OrganizationContext`), no navega y no toca la lista de organizaciones:
/// cuando termina en [OrganizationDeletionStatus.deleted] o
/// [OrganizationDeletionStatus.aborted] la UI pide
/// `AuthUserContextRefreshRequested` y `/me/context` decide el resto.
///
/// Las reglas (intentos, vencimientos, cooldown, vigencia de la autorizacion)
/// son del backend. El bloc decide por status HTTP y por su propio paso, sin
/// contadores locales ni mensajes en ingles.
///
/// Es tenant con alcance de ruta: se crea con la Configuracion de la
/// organizacion y se cierra cuando la pila se reinicia.
class OrganizationDeletionBloc
    extends Bloc<OrganizationDeletionEvent, OrganizationDeletionState> {
  OrganizationDeletionBloc({
    required RequestOrganizationDeletionCode requestOrganizationDeletionCode,
    required VerifyOrganizationDeletionCode verifyOrganizationDeletionCode,
    required DeleteOrganization deleteOrganization,
  }) : _requestCode = requestOrganizationDeletionCode,
       _verifyCode = verifyOrganizationDeletionCode,
       _deleteOrganization = deleteOrganization,
       super(const OrganizationDeletionState()) {
    on<OrganizationDeletionCodeRequested>(_onCodeRequested);
    on<OrganizationDeletionCodeSubmitted>(_onCodeSubmitted);
    on<OrganizationDeletionConfirmed>(_onConfirmed);
    on<OrganizationDeletionCancelled>(_onCancelled);
    on<OrganizationDeletionResendAvailable>(_onResendAvailable);
  }

  final RequestOrganizationDeletionCode _requestCode;
  final VerifyOrganizationDeletionCode _verifyCode;
  final DeleteOrganization _deleteOrganization;

  /// Unico disparo en `resendAvailableAt`. No hay cuenta regresiva.
  Timer? _resendTimer;

  Future<void> _onCodeRequested(
    OrganizationDeletionCodeRequested event,
    Emitter<OrganizationDeletionState> emit,
  ) async {
    final isResend = state.verification != null;

    switch (state.status) {
      case OrganizationDeletionStatus.idle:
      case OrganizationDeletionStatus.aborted:
        break;
      case OrganizationDeletionStatus.awaitingCode:
        // El reenvio respeta `resendAvailableAt`; si igual llega antes de
        // tiempo, el backend responde 429.
        if (isResend && !state.canResend) {
          return;
        }
      case OrganizationDeletionStatus.requestingCode:
      case OrganizationDeletionStatus.verifyingCode:
      case OrganizationDeletionStatus.verified:
      case OrganizationDeletionStatus.deleting:
      case OrganizationDeletionStatus.deleted:
        return;
    }

    emit(
      state.copyWith(
        status: OrganizationDeletionStatus.requestingCode,
        requestErrorMessage: '',
        verifyErrorMessage: '',
        deleteErrorMessage: '',
        isDeleteResultUnknown: false,
      ),
    );

    final result = await _requestCode();

    if (result is Success<RequestedSecurityVerification>) {
      // El codigo nuevo invalida en el backend cualquier codigo o
      // autorizacion anterior: se reemplaza la verificacion, nunca se suma.
      final verification = result.data;
      final canResendNow = _scheduleResend(verification);

      emit(
        OrganizationDeletionState(
          status: OrganizationDeletionStatus.awaitingCode,
          verification: verification,
          canResend: canResendNow,
        ),
      );
      return;
    }

    if (result is FailureResult<RequestedSecurityVerification>) {
      final failure = result.failure;

      if (failure is PermissionDeniedFailure) {
        _abort(emit, requestErrorMessage: failure.message);
        return;
      }

      // 400, 429, 503, red, timeout: no se avanza de paso. En un reenvio
      // fallido el backend deja la verificacion anterior como estaba.
      emit(
        state.copyWith(
          status: isResend
              ? OrganizationDeletionStatus.awaitingCode
              : OrganizationDeletionStatus.idle,
          requestErrorMessage: failure.message,
        ),
      );
    }
  }

  Future<void> _onCodeSubmitted(
    OrganizationDeletionCodeSubmitted event,
    Emitter<OrganizationDeletionState> emit,
  ) async {
    final verification = state.verification;
    if (!state.canSubmitCode || verification == null) {
      return;
    }

    emit(
      state.copyWith(
        status: OrganizationDeletionStatus.verifyingCode,
        verifyErrorMessage: '',
        requestErrorMessage: '',
      ),
    );

    final result = await _verifyCode(
      verificationId: verification.verificationId,
      code: event.code,
    );

    if (result is Success<VerifiedSecurityVerification>) {
      // Verificar no elimina: queda pendiente la confirmacion final.
      emit(
        state.copyWith(
          status: OrganizationDeletionStatus.verified,
          authorization: result.data,
          verifyErrorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<VerifiedSecurityVerification>) {
      final failure = result.failure;

      if (failure is PermissionDeniedFailure) {
        _abort(emit, verifyErrorMessage: failure.message);
        return;
      }

      // 404 inexistente/ajena, 409 vencida/reemplazada/usada, 429 bloqueada:
      // esta verificacion ya no sirve. Un 400 (codigo incorrecto), la red o
      // el timeout la dejan utilizable: el backend lleva la cuenta de
      // intentos.
      final closesVerification =
          failure is ServerFailure &&
          (failure.statusCode == 404 ||
              failure.statusCode == 409 ||
              failure.statusCode == 429);

      emit(
        state.copyWith(
          status: OrganizationDeletionStatus.awaitingCode,
          isVerificationClosed: closesVerification,
          verifyErrorMessage: failure.message,
        ),
      );
    }
  }

  Future<void> _onConfirmed(
    OrganizationDeletionConfirmed event,
    Emitter<OrganizationDeletionState> emit,
  ) async {
    if (state.status != OrganizationDeletionStatus.verified) {
      return;
    }

    emit(
      state.copyWith(
        status: OrganizationDeletionStatus.deleting,
        deleteErrorMessage: '',
        isDeleteResultUnknown: false,
      ),
    );

    // Sin eliminacion optimista: hasta el 204 no cambia nada.
    final result = await _deleteOrganization();

    if (result is Success<void>) {
      _cancelResendTimer();
      emit(
        const OrganizationDeletionState(
          status: OrganizationDeletionStatus.deleted,
        ),
      );
      return;
    }

    if (result is FailureResult<void>) {
      final failure = result.failure;

      // 409: el backend detecto un cambio concurrente e hizo rollback; la
      // autorizacion sigue `VERIFIED` y se puede volver a confirmar.
      if (failure is ServerFailure && failure.statusCode == 409) {
        emit(
          state.copyWith(
            status: OrganizationDeletionStatus.verified,
            deleteErrorMessage: failure.message,
          ),
        );
        return;
      }

      // Fallos que garantizan que no se borro nada: 403 (sin permisos o sin
      // autorizacion vigente), sesion caida o sin organizacion activa.
      if (failure is PermissionDeniedFailure ||
          failure is UnauthorizedFailure ||
          failure is SessionRequiredFailure ||
          failure is OrganizationRequiredFailure) {
        _abort(emit, deleteErrorMessage: failure.message);
        return;
      }

      // Red, timeout o respuesta inesperada despues de enviar el `DELETE`: la
      // organizacion pudo haberse eliminado aunque no llego el 204. No se
      // afirma que fallo ni se reintenta: lo resuelve `/me/context`.
      _abort(
        emit,
        deleteErrorMessage:
            'No pudimos confirmar el resultado de la eliminacion. Estamos '
            'actualizando tus organizaciones: si la organizacion ya no '
            'aparece, se elimino; si sigue apareciendo, puedes volver a '
            'intentar el proceso.',
        isDeleteResultUnknown: true,
      );
    }
  }

  void _onCancelled(
    OrganizationDeletionCancelled event,
    Emitter<OrganizationDeletionState> emit,
  ) {
    if (!state.canCancel) {
      return;
    }

    _cancelResendTimer();
    emit(const OrganizationDeletionState());
  }

  void _onResendAvailable(
    OrganizationDeletionResendAvailable event,
    Emitter<OrganizationDeletionState> emit,
  ) {
    // Un disparo de una verificacion ya reemplazada no habilita nada.
    if (state.verification?.verificationId != event.verificationId) {
      return;
    }

    emit(state.copyWith(canResend: true));
  }

  /// Termina el flujo sin eliminacion confirmada y descarta la verificacion.
  void _abort(
    Emitter<OrganizationDeletionState> emit, {
    String requestErrorMessage = '',
    String verifyErrorMessage = '',
    String deleteErrorMessage = '',
    bool isDeleteResultUnknown = false,
  }) {
    _cancelResendTimer();
    emit(
      OrganizationDeletionState(
        status: OrganizationDeletionStatus.aborted,
        requestErrorMessage: requestErrorMessage,
        verifyErrorMessage: verifyErrorMessage,
        deleteErrorMessage: deleteErrorMessage,
        isDeleteResultUnknown: isDeleteResultUnknown,
      ),
    );
  }

  /// Programa el unico aviso de `resendAvailableAt`.
  ///
  /// Devuelve `true` si ese momento ya paso. Usa el reloj local: si difiere
  /// del servidor, el backend sigue siendo quien acepta o rechaza (429).
  bool _scheduleResend(RequestedSecurityVerification verification) {
    _cancelResendTimer();

    final delay = verification.resendAvailableAt.difference(DateTime.now());
    if (delay <= Duration.zero) {
      return true;
    }

    _resendTimer = Timer(delay, () {
      if (!isClosed) {
        add(OrganizationDeletionResendAvailable(verification.verificationId));
      }
    });
    return false;
  }

  void _cancelResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = null;
  }

  @override
  Future<void> close() {
    _cancelResendTimer();
    return super.close();
  }
}
