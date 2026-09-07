import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../users/domain/entities/user_search_result.dart';
import '../../../users/domain/usecases/search_users.dart';
import '../../domain/entities/invitation_status.dart';
import '../../domain/entities/organization_invitation.dart';
import '../../domain/usecases/accept_organization_invitation.dart';
import '../../domain/usecases/cancel_organization_invitation.dart';
import '../../domain/usecases/create_organization_invitation.dart';
import '../../domain/usecases/get_organization_invitations.dart';
import 'organization_invitation_event.dart';
import 'organization_invitation_state.dart';

/// Invitaciones de organizacion: aceptar una recibida, crear una nueva y
/// administrar las enviadas por la organizacion activa.
///
/// No recarga `/me/context` ni decide navegacion: solo reporta el resultado de
/// cada request. La UI traduce ese resultado en un refresh del contexto
/// (`AuthUserContextRefreshRequested`) o en cerrar el flujo de invitacion.
///
/// Crear invitacion no toca la lista de miembros a proposito: la membresia la
/// crea la aceptacion del invitado, no el envio.
///
/// Se registra como factory y se crea por ruta: al cambiar de organizacion la
/// pila se reinicia, este bloc se cierra y el siguiente arranca sin las
/// invitaciones del tenant anterior.
class OrganizationInvitationBloc
    extends Bloc<OrganizationInvitationEvent, OrganizationInvitationState> {
  OrganizationInvitationBloc({
    required AcceptOrganizationInvitation acceptOrganizationInvitation,
    required SearchUsers searchUsers,
    required CreateOrganizationInvitation createOrganizationInvitation,
    required GetOrganizationInvitations getOrganizationInvitations,
    required CancelOrganizationInvitation cancelOrganizationInvitation,
  }) : _acceptOrganizationInvitation = acceptOrganizationInvitation,
       _searchUsers = searchUsers,
       _createOrganizationInvitation = createOrganizationInvitation,
       _getOrganizationInvitations = getOrganizationInvitations,
       _cancelOrganizationInvitation = cancelOrganizationInvitation,
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
    on<LoadOrganizationInvitationsRequested>(_onLoadInvitationsRequested);
    on<CancelOrganizationInvitationRequested>(_onCancelInvitationRequested);
  }

  final AcceptOrganizationInvitation _acceptOrganizationInvitation;
  final SearchUsers _searchUsers;
  final CreateOrganizationInvitation _createOrganizationInvitation;
  final GetOrganizationInvitations _getOrganizationInvitations;
  final CancelOrganizationInvitation _cancelOrganizationInvitation;

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

  Future<void> _onLoadInvitationsRequested(
    LoadOrganizationInvitationsRequested event,
    Emitter<OrganizationInvitationState> emit,
  ) async {
    emit(
      state.copyWith(
        listStatus: InvitationsListStatus.loading,
        listErrorMessage: '',
      ),
    );

    final result = await _getOrganizationInvitations();

    if (result is Success<List<OrganizationInvitation>>) {
      emit(
        state.copyWith(
          listStatus: InvitationsListStatus.success,
          invitations: result.data,
          listErrorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<List<OrganizationInvitation>>) {
      emit(
        state.copyWith(
          listStatus: InvitationsListStatus.error,
          // Una carga fallida no deja visible el listado anterior.
          invitations: const [],
          listErrorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onCancelInvitationRequested(
    CancelOrganizationInvitationRequested event,
    Emitter<OrganizationInvitationState> emit,
  ) async {
    // Una sola cancelacion a la vez: evita el doble submit sobre la misma
    // invitacion y cancelar dos en paralelo.
    if (state.isCancellingInvitation) {
      return;
    }

    final invitationId = event.invitationId.trim();

    emit(
      state.copyWith(
        cancelStatus: CancelInvitationStatus.cancelling,
        cancellingInvitationId: invitationId,
        cancelErrorMessage: '',
      ),
    );

    final result = await _cancelOrganizationInvitation(
      invitationId: invitationId,
    );

    if (result is Success<void>) {
      // El backend no devuelve la invitacion actualizada, pero el estado
      // resultante de un cancel exitoso es siempre CANCELLED: se refleja en la
      // fila sin recargar el listado.
      emit(
        state.copyWith(
          cancelStatus: CancelInvitationStatus.success,
          invitations: state.invitationsWithStatus(
            invitationId,
            InvitationStatus.cancelled,
          ),
          cancelErrorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<void>) {
      emit(
        state.copyWith(
          cancelStatus: CancelInvitationStatus.error,
          cancelErrorMessage: result.failure.message,
        ),
      );

      // 409: la invitacion cambio de estado por fuera de esta pantalla, asi que
      // el listado quedo viejo. Se recarga para no dejar un `Cancelar` que ya
      // no aplica.
      if (_isConflict(result.failure)) {
        add(const LoadOrganizationInvitationsRequested());
      }
    }
  }

  /// El 409 del backend: la invitacion ya no esta pendiente.
  ///
  /// El datasource lo deja pasar como `HttpStatusException` justamente para
  /// poder reconocerlo aca; el resto de los errores no distingue codigo.
  bool _isConflict(Failure failure) =>
      failure is ServerFailure && failure.statusCode == 409;
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
