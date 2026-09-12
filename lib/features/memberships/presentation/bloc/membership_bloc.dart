import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/membership.dart';
import '../../domain/usecases/change_member_role.dart';
import '../../domain/usecases/get_organization_members.dart';
import '../../domain/usecases/get_organization_members_for_management.dart';
import '../../domain/usecases/reactivate_member.dart';
import '../../domain/usecases/suspend_member.dart';
import 'membership_event.dart';
import 'membership_state.dart';

/// Miembros de la organizacion activa.
///
/// Atiende los dos casos de uso con un solo bloc, porque comparten entidad,
/// contrato de respuesta y forma de listado. Lo que los separa esta explicito
/// en el estado:
///
/// - `LoadMemberDirectoryRequested` -> `GET .../members`, scope `directory`.
/// - `LoadMemberManagementRequested` -> `GET .../members/manage`, scope
///   `management`.
///
/// Cada pantalla crea su propia instancia (el bloc es factory con alcance de
/// ruta) y emite solo su evento de carga, asi que los dos listados nunca
/// conviven en el mismo estado. Las acciones administrativas se ignoran si el
/// scope cargado no es `management`.
///
/// Al cambiar de organizacion la pila se reinicia, el bloc se cierra y el
/// siguiente arranca vacio contra el nuevo tenant.
class MembershipBloc extends Bloc<MembershipEvent, MembershipState> {
  MembershipBloc({
    required GetOrganizationMembers getOrganizationMembers,
    required GetOrganizationMembersForManagement
    getOrganizationMembersForManagement,
    required ChangeMemberRole changeMemberRole,
    required SuspendMember suspendMember,
    required ReactivateMember reactivateMember,
  }) : _getOrganizationMembers = getOrganizationMembers,
       _getOrganizationMembersForManagement =
           getOrganizationMembersForManagement,
       _changeMemberRole = changeMemberRole,
       _suspendMember = suspendMember,
       _reactivateMember = reactivateMember,
       super(const MembershipState()) {
    on<LoadMemberDirectoryRequested>(_onLoadMemberDirectory);
    on<LoadMemberManagementRequested>(_onLoadMemberManagement);
    on<ChangeMemberRoleRequested>(_onChangeMemberRoleRequested);
    on<SuspendMemberRequested>(_onSuspendMemberRequested);
    on<ReactivateMemberRequested>(_onReactivateMemberRequested);
  }

  final GetOrganizationMembers _getOrganizationMembers;
  final GetOrganizationMembersForManagement
  _getOrganizationMembersForManagement;
  final ChangeMemberRole _changeMemberRole;
  final SuspendMember _suspendMember;
  final ReactivateMember _reactivateMember;

  Future<void> _onLoadMemberDirectory(
    LoadMemberDirectoryRequested event,
    Emitter<MembershipState> emit,
  ) {
    return _loadMembers(
      scope: MembershipListScope.directory,
      request: _getOrganizationMembers.call,
      emit: emit,
    );
  }

  Future<void> _onLoadMemberManagement(
    LoadMemberManagementRequested event,
    Emitter<MembershipState> emit,
  ) {
    return _loadMembers(
      scope: MembershipListScope.management,
      request: _getOrganizationMembersForManagement.call,
      emit: emit,
    );
  }

  /// Carga un listado y deja el scope asentado en el estado.
  ///
  /// Tambien limpia la accion administrativa: el listado nuevo no debe heredar
  /// el loading ni el error de la fila anterior.
  Future<void> _loadMembers({
    required MembershipListScope scope,
    required Future<Result<List<Membership>>> Function() request,
    required Emitter<MembershipState> emit,
  }) async {
    emit(
      state.copyWith(
        scope: scope,
        listStatus: MembershipListStatus.loading,
        listErrorMessage: '',
        actionType: MemberActionType.none,
        actionStatus: MemberActionStatus.idle,
        actionMembershipId: '',
        actionErrorMessage: '',
      ),
    );

    final result = await request();

    if (result is Success<List<Membership>>) {
      emit(
        state.copyWith(
          listStatus: MembershipListStatus.success,
          members: result.data,
          listErrorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<List<Membership>>) {
      emit(
        state.copyWith(
          listStatus: MembershipListStatus.error,
          // Una carga fallida no deja visible el listado anterior.
          members: const [],
          listErrorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onChangeMemberRoleRequested(
    ChangeMemberRoleRequested event,
    Emitter<MembershipState> emit,
  ) {
    return _runMemberAction(
      type: MemberActionType.changeRole,
      membershipId: event.membershipId,
      request: (membershipId) =>
          _changeMemberRole(membershipId: membershipId, role: event.role),
      emit: emit,
    );
  }

  Future<void> _onSuspendMemberRequested(
    SuspendMemberRequested event,
    Emitter<MembershipState> emit,
  ) {
    return _runMemberAction(
      type: MemberActionType.suspend,
      membershipId: event.membershipId,
      request: (membershipId) => _suspendMember(membershipId: membershipId),
      emit: emit,
    );
  }

  Future<void> _onReactivateMemberRequested(
    ReactivateMemberRequested event,
    Emitter<MembershipState> emit,
  ) {
    return _runMemberAction(
      type: MemberActionType.reactivate,
      membershipId: event.membershipId,
      request: (membershipId) => _reactivateMember(membershipId: membershipId),
      emit: emit,
    );
  }

  /// Cambio de rol, suspension y reactivacion comparten el mismo ciclo: una
  /// sola accion a la vez, la fila se reemplaza con la membresia que devuelve
  /// el backend y los errores que invalidan el listado lo refrescan.
  Future<void> _runMemberAction({
    required MemberActionType type,
    required String membershipId,
    required Future<Result<Membership>> Function(String membershipId) request,
    required Emitter<MembershipState> emit,
  }) async {
    // Las acciones administrativas solo existen sobre el listado `manage`: el
    // directorio no las ofrece y tampoco debe aplicarlas.
    if (!state.isManagementScope) {
      return;
    }

    // Una sola accion a la vez: evita el doble submit sobre el mismo miembro y
    // dos administraciones en paralelo.
    if (state.isRunningAction) {
      return;
    }

    final normalizedId = membershipId.trim();

    emit(
      state.copyWith(
        actionType: type,
        actionStatus: MemberActionStatus.running,
        actionMembershipId: normalizedId,
        actionErrorMessage: '',
      ),
    );

    final result = await request(normalizedId);

    if (result is Success<Membership>) {
      // El backend devuelve la membresia actualizada: se reemplaza solo esa
      // fila, sin recargar el listado completo. Un miembro suspendido sigue
      // visible en administracion, ahora con `status = SUSPENDED`.
      emit(
        state.copyWith(
          actionStatus: MemberActionStatus.success,
          members: state.membersWithUpdated(result.data),
          actionErrorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Membership>) {
      emit(
        state.copyWith(
          actionStatus: MemberActionStatus.error,
          actionErrorMessage: result.failure.message,
        ),
      );

      // 409: el miembro cambio por fuera de esta pantalla (otro rol, otro
      // status) y el listado quedo viejo.
      // 403: el requester perdio privilegios o el miembro dejo de estar a su
      // alcance; recargar evita dejar una UI aparentemente editable.
      if (_requiresReload(result.failure)) {
        add(const LoadMemberManagementRequested());
      }
    }
  }

  /// Errores despues de los cuales el listado en pantalla ya no es confiable.
  ///
  /// El 409 del backend significa que el miembro cambio por otro lado; el 403,
  /// que la accion que se estaba ofreciendo no corresponde. El datasource deja
  /// pasar el 409 como `HttpStatusException` justamente para poder
  /// reconocerlo aca; el resto de los errores no distingue codigo.
  bool _requiresReload(Failure failure) {
    if (failure is PermissionDeniedFailure) {
      return true;
    }

    return failure is ServerFailure && failure.statusCode == 409;
  }
}
