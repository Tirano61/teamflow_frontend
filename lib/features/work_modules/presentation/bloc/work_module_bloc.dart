import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../components/domain/entities/component.dart';
import '../../domain/entities/work_module.dart';
import '../../domain/usecases/associate_component_to_work_module.dart';
import '../../domain/usecases/create_work_module.dart';
import '../../domain/usecases/get_work_module.dart';
import '../../domain/usecases/get_work_module_components.dart';
import '../../domain/usecases/get_work_modules.dart';
import '../../domain/usecases/remove_component_from_work_module.dart';
import '../../domain/usecases/set_work_module_active.dart';
import '../../domain/usecases/update_work_module.dart';
import 'work_module_event.dart';
import 'work_module_state.dart';

class WorkModuleBloc extends Bloc<WorkModuleEvent, WorkModuleState> {
  WorkModuleBloc({
    required GetWorkModules getModules,
    required GetWorkModule getModule,
    required CreateWorkModule createModule,
    required UpdateWorkModule updateModule,
    required SetWorkModuleActive setModuleActive,
    required GetWorkModuleComponents getModuleComponents,
    required AssociateComponentToWorkModule associateComponent,
    required RemoveComponentFromWorkModule removeAssociatedComponent,
  })  : _getModules = getModules,
        _getModule = getModule,
        _createModule = createModule,
        _updateModule = updateModule,
        _setModuleActive = setModuleActive,
        _getModuleComponents = getModuleComponents,
        _associateComponent = associateComponent,
        _removeAssociatedComponent = removeAssociatedComponent,
        super(const WorkModuleState()) {
    on<LoadWorkModulesEvent>(_onLoadWorkModules);
    on<LoadWorkModuleEvent>(_onLoadWorkModule);
    on<CreateWorkModuleEvent>(_onCreateWorkModule);
    on<UpdateWorkModuleEvent>(_onUpdateWorkModule);
    on<SetWorkModuleActiveEvent>(_onSetWorkModuleActive);
    on<LoadWorkModuleComponentsEvent>(_onLoadWorkModuleComponents);
    on<AssociateComponentEvent>(_onAssociateComponent);
    on<RemoveAssociatedComponentEvent>(_onRemoveAssociatedComponent);
  }

  final GetWorkModules _getModules;
  final GetWorkModule _getModule;
  final CreateWorkModule _createModule;
  final UpdateWorkModule _updateModule;
  final SetWorkModuleActive _setModuleActive;
  final GetWorkModuleComponents _getModuleComponents;
  final AssociateComponentToWorkModule _associateComponent;
  final RemoveComponentFromWorkModule _removeAssociatedComponent;

  Future<void> _onLoadWorkModules(
    LoadWorkModulesEvent event,
    Emitter<WorkModuleState> emit,
  ) async {
    emit(
      state.copyWith(
        status: WorkModuleStatus.loading,
        errorMessage: '',
        clearSelectedWorkModule: true,
      ),
    );

    final result = await _getModules(includeInactive: event.includeInactive);

    if (result is Success<List<WorkModule>>) {
      emit(
        state.copyWith(
          status: WorkModuleStatus.success,
          workModules: result.data,
          selectedWorkModuleComponents: const [],
          isLoadingWorkModuleComponents: false,
          isUpdatingWorkModuleComponents: false,
          errorMessage: '',
          clearSelectedWorkModule: true,
        ),
      );
      return;
    }

    if (result is FailureResult<List<WorkModule>>) {
      emit(
        state.copyWith(
          status: WorkModuleStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onLoadWorkModule(
    LoadWorkModuleEvent event,
    Emitter<WorkModuleState> emit,
  ) async {
    emit(
      state.copyWith(
        status: WorkModuleStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _getModule(event.id);

    if (result is Success<WorkModule>) {
      final selected = result.data;
      emit(
        state.copyWith(
          status: WorkModuleStatus.success,
          selectedWorkModule: selected,
          workModules: _upsertById(state.workModules, selected),
          selectedWorkModuleComponents: const [],
          isLoadingWorkModuleComponents: false,
          isUpdatingWorkModuleComponents: false,
          errorMessage: '',
        ),
      );
      final id = selected.id?.trim() ?? '';
      if (id.isNotEmpty) {
        add(LoadWorkModuleComponentsEvent(id));
      }
      return;
    }

    if (result is FailureResult<WorkModule>) {
      emit(
        state.copyWith(
          status: WorkModuleStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onSetWorkModuleActive(
    SetWorkModuleActiveEvent event,
    Emitter<WorkModuleState> emit,
  ) async {
    emit(state.copyWith(status: WorkModuleStatus.loading, errorMessage: ''));

    final result = await _setModuleActive(id: event.id, active: event.active);

    if (result is Success<WorkModule>) {
      final updated = result.data;
      emit(
        state.copyWith(
          status: WorkModuleStatus.success,
          selectedWorkModule:
              state.selectedWorkModule?.id == updated.id ? updated : state.selectedWorkModule,
          workModules: _upsertById(state.workModules, updated),
          errorMessage: '',
        ),
      );

      final selectedId = state.selectedWorkModule?.id?.trim() ?? '';
      if (selectedId.isNotEmpty && selectedId == updated.id?.trim()) {
        add(LoadWorkModuleComponentsEvent(selectedId));
      }
      return;
    }

    if (result is FailureResult<WorkModule>) {
      emit(
        state.copyWith(
          status: WorkModuleStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onLoadWorkModuleComponents(
    LoadWorkModuleComponentsEvent event,
    Emitter<WorkModuleState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingWorkModuleComponents: true,
        errorMessage: '',
      ),
    );

    final result = await _getModuleComponents(event.workModuleId);

    if (result is Success<List<Component>>) {
      emit(
        state.copyWith(
          isLoadingWorkModuleComponents: false,
          selectedWorkModuleComponents: List.unmodifiable(result.data),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<List<Component>>) {
      emit(
        state.copyWith(
          isLoadingWorkModuleComponents: false,
          status: WorkModuleStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onAssociateComponent(
    AssociateComponentEvent event,
    Emitter<WorkModuleState> emit,
  ) async {
    emit(state.copyWith(isUpdatingWorkModuleComponents: true, errorMessage: ''));

    final result = await _associateComponent(
      workModuleId: event.workModuleId,
      componentId: event.componentId,
    );

    if (result is Success<void>) {
      emit(state.copyWith(isUpdatingWorkModuleComponents: false, errorMessage: ''));
      add(LoadWorkModuleComponentsEvent(event.workModuleId));
      return;
    }

    if (result is FailureResult<void>) {
      emit(
        state.copyWith(
          isUpdatingWorkModuleComponents: false,
          status: WorkModuleStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onRemoveAssociatedComponent(
    RemoveAssociatedComponentEvent event,
    Emitter<WorkModuleState> emit,
  ) async {
    emit(state.copyWith(isUpdatingWorkModuleComponents: true, errorMessage: ''));

    final result = await _removeAssociatedComponent(
      workModuleId: event.workModuleId,
      componentId: event.componentId,
    );

    if (result is Success<void>) {
      emit(state.copyWith(isUpdatingWorkModuleComponents: false, errorMessage: ''));
      add(LoadWorkModuleComponentsEvent(event.workModuleId));
      return;
    }

    if (result is FailureResult<void>) {
      emit(
        state.copyWith(
          isUpdatingWorkModuleComponents: false,
          status: WorkModuleStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onCreateWorkModule(
    CreateWorkModuleEvent event,
    Emitter<WorkModuleState> emit,
  ) async {
    emit(
      state.copyWith(
        status: WorkModuleStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _createModule(event.workModule);

    if (result is Success<WorkModule>) {
      final created = result.data;
      emit(
        state.copyWith(
          status: WorkModuleStatus.success,
          selectedWorkModule: created,
          workModules: _upsertById(state.workModules, created),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<WorkModule>) {
      emit(
        state.copyWith(
          status: WorkModuleStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onUpdateWorkModule(
    UpdateWorkModuleEvent event,
    Emitter<WorkModuleState> emit,
  ) async {
    emit(
      state.copyWith(
        status: WorkModuleStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _updateModule(event.workModule);

    if (result is Success<WorkModule>) {
      final updated = result.data;
      emit(
        state.copyWith(
          status: WorkModuleStatus.success,
          selectedWorkModule: updated,
          workModules: _upsertById(state.workModules, updated),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<WorkModule>) {
      emit(
        state.copyWith(
          status: WorkModuleStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  List<WorkModule> _upsertById(
    List<WorkModule> current,
    WorkModule workModule,
  ) {
    final next = List<WorkModule>.from(current);
    final index = next.indexWhere(
      (item) =>
          item.id != null &&
          workModule.id != null &&
          item.id == workModule.id,
    );

    if (index >= 0) {
      next[index] = workModule;
      return List<WorkModule>.unmodifiable(next);
    }

    next.add(workModule);
    return List<WorkModule>.unmodifiable(next);
  }
}


