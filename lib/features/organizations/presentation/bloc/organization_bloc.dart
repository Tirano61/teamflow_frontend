import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/organization.dart';
import '../../domain/usecases/create_organization.dart';
import 'organization_event.dart';
import 'organization_state.dart';

/// Estado de la creacion de organizaciones.
///
/// No decide navegacion ni recarga `/me/context`: solo reporta el resultado
/// de `POST /organizations`. La UI traduce ese resultado en un refresh del
/// contexto (`AuthUserContextRefreshRequested`).
class OrganizationBloc extends Bloc<OrganizationEvent, OrganizationState> {
  OrganizationBloc({required CreateOrganization createOrganization})
    : _createOrganization = createOrganization,
      super(const OrganizationState()) {
    on<CreateOrganizationRequested>(_onCreateOrganizationRequested);
  }

  final CreateOrganization _createOrganization;

  Future<void> _onCreateOrganizationRequested(
    CreateOrganizationRequested event,
    Emitter<OrganizationState> emit,
  ) async {
    if (state.isCreating) {
      return;
    }

    final name = event.name.trim();
    if (name.isEmpty) {
      emit(
        state.copyWith(
          status: OrganizationStatus.error,
          errorMessage: 'El nombre de la organizacion es obligatorio.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: OrganizationStatus.creating, errorMessage: ''),
    );

    final result = await _createOrganization(name: name);

    if (result is Success<Organization>) {
      emit(
        state.copyWith(
          status: OrganizationStatus.success,
          createdOrganization: result.data,
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Organization>) {
      emit(
        state.copyWith(
          status: OrganizationStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }
}
