import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../indicators/domain/entities/indicator.dart';
import '../../domain/entities/application.dart';
import '../../domain/usecases/associate_indicator_to_application.dart';
import '../../domain/usecases/create_application.dart';
import '../../domain/usecases/get_application.dart';
import '../../domain/usecases/get_application_indicators.dart';
import '../../domain/usecases/get_applications.dart';
import '../../domain/usecases/remove_indicator_from_application.dart';
import '../../domain/usecases/set_application_active.dart';
import '../../domain/usecases/update_application.dart';
import 'application_event.dart';
import 'application_state.dart';

class ApplicationBloc extends Bloc<ApplicationEvent, ApplicationState> {
  ApplicationBloc({
    required GetApplications getApplications,
    required GetApplication getApplication,
    required CreateApplication createApplication,
    required UpdateApplication updateApplication,
    required SetApplicationActive setApplicationActive,
    required GetApplicationIndicators getApplicationIndicators,
    required AssociateIndicatorToApplication associateIndicator,
    required RemoveIndicatorFromApplication removeAssociatedIndicator,
  })  : _getApplications = getApplications,
        _getApplication = getApplication,
        _createApplication = createApplication,
        _updateApplication = updateApplication,
        _setApplicationActive = setApplicationActive,
        _getApplicationIndicators = getApplicationIndicators,
        _associateIndicator = associateIndicator,
        _removeAssociatedIndicator = removeAssociatedIndicator,
        super(const ApplicationState()) {
    on<LoadApplicationsEvent>(_onLoadApplications);
    on<LoadApplicationEvent>(_onLoadApplication);
    on<CreateApplicationEvent>(_onCreateApplication);
    on<UpdateApplicationEvent>(_onUpdateApplication);
    on<SetApplicationActiveEvent>(_onSetApplicationActive);
    on<LoadApplicationIndicatorsEvent>(_onLoadApplicationIndicators);
    on<AssociateIndicatorEvent>(_onAssociateIndicator);
    on<RemoveAssociatedIndicatorEvent>(_onRemoveAssociatedIndicator);
  }

  final GetApplications _getApplications;
  final GetApplication _getApplication;
  final CreateApplication _createApplication;
  final UpdateApplication _updateApplication;
  final SetApplicationActive _setApplicationActive;
  final GetApplicationIndicators _getApplicationIndicators;
  final AssociateIndicatorToApplication _associateIndicator;
  final RemoveIndicatorFromApplication _removeAssociatedIndicator;

  Future<void> _onLoadApplications(
    LoadApplicationsEvent event,
    Emitter<ApplicationState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ApplicationStatus.loading,
        errorMessage: '',
        clearSelectedApplication: true,
      ),
    );

    final result = await _getApplications(includeInactive: event.includeInactive);

    if (result is Success<List<Application>>) {
      emit(
        state.copyWith(
          status: ApplicationStatus.success,
          applications: result.data,
          selectedApplicationIndicators: const [],
          isLoadingApplicationIndicators: false,
          isUpdatingApplicationIndicators: false,
          errorMessage: '',
          clearSelectedApplication: true,
        ),
      );
      return;
    }

    if (result is FailureResult<List<Application>>) {
      emit(
        state.copyWith(
          status: ApplicationStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onLoadApplication(
    LoadApplicationEvent event,
    Emitter<ApplicationState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ApplicationStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _getApplication(event.id);

    if (result is Success<Application>) {
      final selected = result.data;
      emit(
        state.copyWith(
          status: ApplicationStatus.success,
          selectedApplication: selected,
          applications: _upsertById(state.applications, selected),
          selectedApplicationIndicators: const [],
          isLoadingApplicationIndicators: false,
          isUpdatingApplicationIndicators: false,
          errorMessage: '',
        ),
      );
      final id = selected.id?.trim() ?? '';
      if (id.isNotEmpty) {
        add(LoadApplicationIndicatorsEvent(id));
      }
      return;
    }

    if (result is FailureResult<Application>) {
      emit(
        state.copyWith(
          status: ApplicationStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onSetApplicationActive(
    SetApplicationActiveEvent event,
    Emitter<ApplicationState> emit,
  ) async {
    emit(state.copyWith(status: ApplicationStatus.loading, errorMessage: ''));

    final result = await _setApplicationActive(id: event.id, active: event.active);

    if (result is Success<Application>) {
      final updated = result.data;
      emit(
        state.copyWith(
          status: ApplicationStatus.success,
          selectedApplication:
              state.selectedApplication?.id == updated.id ? updated : state.selectedApplication,
          applications: _upsertById(state.applications, updated),
          errorMessage: '',
        ),
      );

      final selectedId = state.selectedApplication?.id?.trim() ?? '';
      if (selectedId.isNotEmpty && selectedId == updated.id?.trim()) {
        add(LoadApplicationIndicatorsEvent(selectedId));
      }
      return;
    }

    if (result is FailureResult<Application>) {
      emit(
        state.copyWith(
          status: ApplicationStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onLoadApplicationIndicators(
    LoadApplicationIndicatorsEvent event,
    Emitter<ApplicationState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingApplicationIndicators: true,
        errorMessage: '',
      ),
    );

    final result = await _getApplicationIndicators(event.applicationId);

    if (result is Success<List<Indicator>>) {
      emit(
        state.copyWith(
          isLoadingApplicationIndicators: false,
          selectedApplicationIndicators: List.unmodifiable(result.data),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<List<Indicator>>) {
      emit(
        state.copyWith(
          isLoadingApplicationIndicators: false,
          status: ApplicationStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onAssociateIndicator(
    AssociateIndicatorEvent event,
    Emitter<ApplicationState> emit,
  ) async {
    emit(state.copyWith(isUpdatingApplicationIndicators: true, errorMessage: ''));

    final result = await _associateIndicator(
      applicationId: event.applicationId,
      indicatorId: event.indicatorId,
    );

    if (result is Success<void>) {
      emit(state.copyWith(isUpdatingApplicationIndicators: false, errorMessage: ''));
      add(LoadApplicationIndicatorsEvent(event.applicationId));
      return;
    }

    if (result is FailureResult<void>) {
      emit(
        state.copyWith(
          isUpdatingApplicationIndicators: false,
          status: ApplicationStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onRemoveAssociatedIndicator(
    RemoveAssociatedIndicatorEvent event,
    Emitter<ApplicationState> emit,
  ) async {
    emit(state.copyWith(isUpdatingApplicationIndicators: true, errorMessage: ''));

    final result = await _removeAssociatedIndicator(
      applicationId: event.applicationId,
      indicatorId: event.indicatorId,
    );

    if (result is Success<void>) {
      emit(state.copyWith(isUpdatingApplicationIndicators: false, errorMessage: ''));
      add(LoadApplicationIndicatorsEvent(event.applicationId));
      return;
    }

    if (result is FailureResult<void>) {
      emit(
        state.copyWith(
          isUpdatingApplicationIndicators: false,
          status: ApplicationStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onCreateApplication(
    CreateApplicationEvent event,
    Emitter<ApplicationState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ApplicationStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _createApplication(event.application);

    if (result is Success<Application>) {
      final created = result.data;
      emit(
        state.copyWith(
          status: ApplicationStatus.success,
          selectedApplication: created,
          applications: _upsertById(state.applications, created),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Application>) {
      emit(
        state.copyWith(
          status: ApplicationStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onUpdateApplication(
    UpdateApplicationEvent event,
    Emitter<ApplicationState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ApplicationStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _updateApplication(event.application);

    if (result is Success<Application>) {
      final updated = result.data;
      emit(
        state.copyWith(
          status: ApplicationStatus.success,
          selectedApplication: updated,
          applications: _upsertById(state.applications, updated),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Application>) {
      emit(
        state.copyWith(
          status: ApplicationStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  List<Application> _upsertById(
    List<Application> current,
    Application application,
  ) {
    final next = List<Application>.from(current);
    final index = next.indexWhere(
      (item) =>
          item.id != null &&
          application.id != null &&
          item.id == application.id,
    );

    if (index >= 0) {
      next[index] = application;
      return List<Application>.unmodifiable(next);
    }

    next.add(application);
    return List<Application>.unmodifiable(next);
  }
}