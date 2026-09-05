import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/usecases/accept_organization_invitation.dart';
import 'organization_invitation_event.dart';
import 'organization_invitation_state.dart';

/// Estado de la aceptacion de invitaciones pendientes.
///
/// No recarga `/me/context` ni decide navegacion: solo reporta el resultado
/// de `POST /organization-invitations/{token}/accept`. La UI traduce ese
/// resultado en un refresh del contexto (`AuthUserContextRefreshRequested`).
class OrganizationInvitationBloc
    extends Bloc<OrganizationInvitationEvent, OrganizationInvitationState> {
  OrganizationInvitationBloc({
    required AcceptOrganizationInvitation acceptOrganizationInvitation,
  }) : _acceptOrganizationInvitation = acceptOrganizationInvitation,
       super(const OrganizationInvitationState()) {
    on<AcceptOrganizationInvitationRequested>(_onAcceptRequested);
  }

  final AcceptOrganizationInvitation _acceptOrganizationInvitation;

  Future<void> _onAcceptRequested(
    AcceptOrganizationInvitationRequested event,
    Emitter<OrganizationInvitationState> emit,
  ) async {
    // Una sola aceptacion a la vez: evita el doble submit sobre la misma
    // invitacion y aceptar dos invitaciones en paralelo.
    if (state.isAccepting) {
      return;
    }

    final token = event.token.trim();

    emit(
      state.copyWith(
        status: OrganizationInvitationStatus.accepting,
        processingToken: token,
        errorMessage: '',
      ),
    );

    final result = await _acceptOrganizationInvitation(token: token);

    if (result is Success<void>) {
      emit(
        state.copyWith(
          status: OrganizationInvitationStatus.success,
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<void>) {
      emit(
        state.copyWith(
          status: OrganizationInvitationStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }
}
