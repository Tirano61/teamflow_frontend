import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/membership.dart';
import '../../domain/usecases/change_member_role.dart';
import '../../domain/usecases/get_organization_members.dart';
import 'membership_event.dart';
import 'membership_state.dart';

/// Miembros de la organizacion activa.
///
/// Se registra como factory y se crea por ruta: al cambiar de organizacion la
/// pila se reinicia, este bloc se cierra y el siguiente arranca vacio contra el
/// nuevo tenant.
class MembershipBloc extends Bloc<MembershipEvent, MembershipState> {
  MembershipBloc({
    required GetOrganizationMembers getOrganizationMembers,
    required ChangeMemberRole changeMemberRole,
  }) : _getOrganizationMembers = getOrganizationMembers,
       _changeMemberRole = changeMemberRole,
       super(const MembershipState()) {
    on<LoadOrganizationMembersEvent>(_onLoadOrganizationMembers);
    on<ChangeMemberRoleRequested>(_onChangeMemberRoleRequested);
  }

  final GetOrganizationMembers _getOrganizationMembers;
  final ChangeMemberRole _changeMemberRole;

  Future<void> _onLoadOrganizationMembers(
    LoadOrganizationMembersEvent event,
    Emitter<MembershipState> emit,
  ) async {
    emit(state.copyWith(status: MembershipStatus.loading, errorMessage: ''));

    final result = await _getOrganizationMembers();

    if (result is Success<List<Membership>>) {
      emit(
        state.copyWith(
          status: MembershipStatus.success,
          members: result.data,
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<List<Membership>>) {
      emit(
        state.copyWith(
          status: MembershipStatus.error,
          // Una carga fallida no deja visible el listado anterior.
          members: const [],
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onChangeMemberRoleRequested(
    ChangeMemberRoleRequested event,
    Emitter<MembershipState> emit,
  ) async {
    // Un solo cambio a la vez: evita el doble submit sobre el mismo miembro y
    // cambiar dos roles en paralelo.
    if (state.isChangingRole) {
      return;
    }

    final membershipId = event.membershipId.trim();

    emit(
      state.copyWith(
        changeRoleStatus: ChangeMemberRoleStatus.saving,
        changingMembershipId: membershipId,
        changeRoleErrorMessage: '',
      ),
    );

    final result = await _changeMemberRole(
      membershipId: membershipId,
      role: event.role,
    );

    if (result is Success<Membership>) {
      // El backend devuelve la membresia actualizada: se reemplaza solo esa
      // fila, sin recargar el listado completo.
      emit(
        state.copyWith(
          changeRoleStatus: ChangeMemberRoleStatus.success,
          members: state.membersWithUpdated(result.data),
          changeRoleErrorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Membership>) {
      emit(
        state.copyWith(
          changeRoleStatus: ChangeMemberRoleStatus.error,
          changeRoleErrorMessage: result.failure.message,
        ),
      );

      // 409: el miembro cambio por fuera de esta pantalla, asi que el listado
      // quedo viejo. Se recarga para no dejar visible un rol que ya no es el
      // real ni una accion que ya no aplica.
      if (_isConflict(result.failure)) {
        add(const LoadOrganizationMembersEvent());
      }
    }
  }

  /// El 409 del backend: el miembro cambio de rol por otro lado o dejo de
  /// estar `ACTIVE`.
  ///
  /// El datasource lo deja pasar como `HttpStatusException` justamente para
  /// poder reconocerlo aca; el resto de los errores no distingue codigo.
  bool _isConflict(Failure failure) =>
      failure is ServerFailure && failure.statusCode == 409;
}
