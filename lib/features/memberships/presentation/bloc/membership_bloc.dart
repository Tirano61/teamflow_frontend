import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/membership.dart';
import '../../domain/usecases/get_organization_members.dart';
import 'membership_event.dart';
import 'membership_state.dart';

/// Miembros de la organizacion activa.
///
/// Se registra como factory y se crea por ruta: al cambiar de organizacion la
/// pila se reinicia, este bloc se cierra y el siguiente arranca vacio contra el
/// nuevo tenant.
class MembershipBloc extends Bloc<MembershipEvent, MembershipState> {
  MembershipBloc({required GetOrganizationMembers getOrganizationMembers})
    : _getOrganizationMembers = getOrganizationMembers,
      super(const MembershipState()) {
    on<LoadOrganizationMembersEvent>(_onLoadOrganizationMembers);
  }

  final GetOrganizationMembers _getOrganizationMembers;

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
}
