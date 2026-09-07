import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../users/domain/entities/user_search_result.dart';
import '../../../users/domain/usecases/search_users.dart';
import '../../domain/usecases/accept_organization_invitation.dart';
import '../../domain/usecases/create_organization_invitation.dart';
import 'organization_invitation_event.dart';
import 'organization_invitation_state.dart';

/// Invitaciones de organizacion: aceptar una recibida y crear una nueva.
///
/// No recarga `/me/context` ni decide navegacion: solo reporta el resultado de
/// cada request. La UI traduce ese resultado en un refresh del contexto
/// (`AuthUserContextRefreshRequested`) o en cerrar el flujo de invitacion.
///
/// Crear invitacion no toca la lista de miembros a proposito: la membresia la
/// crea la aceptacion del invitado, no el envio.
class OrganizationInvitationBloc
    extends Bloc<OrganizationInvitationEvent, OrganizationInvitationState> {
  OrganizationInvitationBloc({
    required AcceptOrganizationInvitation acceptOrganizationInvitation,
    required SearchUsers searchUsers,
    required CreateOrganizationInvitation createOrganizationInvitation,
  }) : _acceptOrganizationInvitation = acceptOrganizationInvitation,
       _searchUsers = searchUsers,
       _createOrganizationInvitation = createOrganizationInvitation,
       super(const OrganizationInvitationState()) {
    on<AcceptOrganizationInvitationRequested>(_onAcceptRequested);
    on<InvitationUserSearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: _debounce(searchDebounce),
    );
    on<InvitationRecipientSelected>(_onRecipientSelected);
    on<InvitationRecipientCleared>(_onRecipientCleared);
    on<InvitationRoleChanged>(_onRoleChanged);
    on<CreateOrganizationInvitationRequested>(_onCreateRequested);
  }

  final AcceptOrganizationInvitation _acceptOrganizationInvitation;
  final SearchUsers _searchUsers;
  final CreateOrganizationInvitation _createOrganizationInvitation;

  /// Minimo de caracteres que exige `GET /users/search`.
  ///
  /// Por debajo no se dispara ninguna request: el backend la rechazaria igual.
  static const int minSearchQueryLength = 2;

  /// Espera entre la ultima tecla y la request.
  ///
  /// Corta como para no notar retardo al escribir, larga como para no mandar
  /// una request por tecla.
  static const Duration searchDebounce = Duration(milliseconds: 350);

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

  Future<void> _onSearchQueryChanged(
    InvitationUserSearchQueryChanged event,
    Emitter<OrganizationInvitationState> emit,
  ) async {
    // La tecla pendiente del debounce puede llegar despues de que el usuario ya
    // eligio destinatario: en ese paso el buscador no esta en pantalla.
    if (state.hasRecipient) {
      return;
    }

    final query = event.query.trim();

    if (query.length < minSearchQueryLength) {
      emit(
        state.copyWith(
          searchQuery: query,
          searchStatus: InvitationUserSearchStatus.idle,
          searchResults: const [],
          searchErrorMessage: '',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        searchQuery: query,
        searchStatus: InvitationUserSearchStatus.loading,
        searchErrorMessage: '',
      ),
    );

    final result = await _searchUsers(query: query);

    // Entre medio pudo llegar otra tecla o una seleccion: el resultado viejo
    // no debe pisar lo que se esta mostrando ahora.
    if (state.searchQuery != query) {
      return;
    }

    if (result is Success<List<UserSearchResult>>) {
      emit(
        state.copyWith(
          searchStatus: InvitationUserSearchStatus.success,
          searchResults: result.data,
          searchErrorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<List<UserSearchResult>>) {
      emit(
        state.copyWith(
          searchStatus: InvitationUserSearchStatus.error,
          searchResults: const [],
          searchErrorMessage: result.failure.message,
        ),
      );
    }
  }

  void _onRecipientSelected(
    InvitationRecipientSelected event,
    Emitter<OrganizationInvitationState> emit,
  ) {
    // El buscador se vacia con la seleccion: al pulsar `Cambiar` se arranca una
    // busqueda nueva en vez de reusar resultados viejos.
    emit(
      state.copyWith(
        selectedUser: event.user,
        searchQuery: '',
        searchStatus: InvitationUserSearchStatus.idle,
        searchResults: const [],
        searchErrorMessage: '',
        createStatus: CreateInvitationStatus.initial,
        createErrorMessage: '',
      ),
    );
  }

  void _onRecipientCleared(
    InvitationRecipientCleared event,
    Emitter<OrganizationInvitationState> emit,
  ) {
    if (state.isSendingInvitation) {
      return;
    }

    emit(
      state.copyWith(
        clearSelectedUser: true,
        searchQuery: '',
        searchStatus: InvitationUserSearchStatus.idle,
        searchResults: const [],
        searchErrorMessage: '',
        createStatus: CreateInvitationStatus.initial,
        createErrorMessage: '',
      ),
    );
  }

  void _onRoleChanged(
    InvitationRoleChanged event,
    Emitter<OrganizationInvitationState> emit,
  ) {
    if (state.isSendingInvitation) {
      return;
    }

    emit(
      state.copyWith(
        selectedRole: event.role,
        createStatus: CreateInvitationStatus.initial,
        createErrorMessage: '',
      ),
    );
  }

  Future<void> _onCreateRequested(
    CreateOrganizationInvitationRequested event,
    Emitter<OrganizationInvitationState> emit,
  ) async {
    // Un solo envio a la vez: el boton tambien se deshabilita, esta guarda
    // cubre el evento repetido.
    if (state.isSendingInvitation) {
      return;
    }

    final recipient = state.selectedUser;
    if (recipient == null) {
      emit(
        state.copyWith(
          createStatus: CreateInvitationStatus.error,
          createErrorMessage:
              'Selecciona un usuario de la busqueda antes de invitar.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        createStatus: CreateInvitationStatus.sending,
        createErrorMessage: '',
      ),
    );

    // Se envia el id del usuario elegido, nunca el texto del buscador.
    final result = await _createOrganizationInvitation(
      userId: recipient.id,
      role: state.selectedRole,
    );

    if (result is Success<void>) {
      emit(
        state.copyWith(
          createStatus: CreateInvitationStatus.success,
          createErrorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<void>) {
      emit(
        state.copyWith(
          createStatus: CreateInvitationStatus.error,
          createErrorMessage: result.failure.message,
        ),
      );
    }
  }
}

/// Debounce + procesamiento secuencial para los eventos del buscador.
///
/// Sin dependencias extra (`bloc_concurrency` no esta en el proyecto): cada
/// tecla reinicia la espera y solo el ultimo evento llega al handler.
EventTransformer<E> _debounce<E>(Duration duration) {
  return (events, mapper) => _debounced(events, duration).asyncExpand(mapper);
}

Stream<E> _debounced<E>(Stream<E> events, Duration duration) {
  Timer? timer;

  return events.transform(
    StreamTransformer<E, E>.fromHandlers(
      handleData: (event, sink) {
        timer?.cancel();
        timer = Timer(duration, () => sink.add(event));
      },
      handleError: (error, stackTrace, sink) {
        timer?.cancel();
        sink.addError(error, stackTrace);
      },
      handleDone: (sink) {
        // Al cerrar el bloc se descarta la tecla pendiente: nada se emite
        // despues del cierre.
        timer?.cancel();
        sink.close();
      },
    ),
  );
}
