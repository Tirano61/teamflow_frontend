import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../work_modules/domain/entities/work_module.dart';
import '../../../work_modules/domain/usecases/associate_component_to_work_module.dart';
import '../../../work_modules/domain/usecases/remove_component_from_work_module.dart';
import '../../domain/entities/component.dart';
import '../../domain/usecases/create_component.dart';
import '../../domain/usecases/get_component.dart';
import '../../domain/usecases/get_component_work_modules.dart';
import '../../domain/usecases/get_components.dart';
import '../../domain/usecases/set_component_active.dart';
import '../../domain/usecases/update_component.dart';
import 'component_event.dart';
import 'component_state.dart';

class ComponentBloc extends Bloc<ComponentEvent, ComponentState> {
  ComponentBloc({
    required GetComponents getComponents,
    required GetComponent getComponent,
    required CreateComponent createComponent,
    required UpdateComponent updateComponent,
    required SetComponentActive setComponentActive,
    required GetComponentWorkModules getComponentModules,
    required AssociateComponentToWorkModule associateWorkModule,
    required RemoveComponentFromWorkModule removeWorkModule,
  })  : _getComponents = getComponents,
        _getComponent = getComponent,
        _createComponent = createComponent,
        _updateComponent = updateComponent,
        _setComponentActive = setComponentActive,
        _getComponentModules = getComponentModules,
        _associateWorkModule = associateWorkModule,
        _removeWorkModule = removeWorkModule,
        super(const ComponentState()) {
    on<LoadComponentsEvent>(_onLoadComponents);
    on<LoadComponentEvent>(_onLoadComponent);
    on<CreateComponentEvent>(_onCreateComponent);
    on<UpdateComponentEvent>(_onUpdateComponent);
    on<SetComponentActiveEvent>(_onSetComponentActive);
    on<LoadComponentWorkModulesEvent>(_onLoadComponentModules);
    on<AssociateWorkModuleToComponentEvent>(_onAssociateWorkModule);
    on<RemoveWorkModuleFromComponentEvent>(_onRemoveWorkModule);
  }

  final GetComponents _getComponents;
  final GetComponent _getComponent;
  final CreateComponent _createComponent;
  final UpdateComponent _updateComponent;
  final SetComponentActive _setComponentActive;
  final GetComponentWorkModules _getComponentModules;

  // La relacion WorkModule <-> Component es una sola ManyToMany y el backend
  // la expone del lado WorkModule. Desde Component se reutilizan los mismos
  // casos de uso, sin duplicar la capa data.
  final AssociateComponentToWorkModule _associateWorkModule;
  final RemoveComponentFromWorkModule _removeWorkModule;

  Future<void> _onLoadComponents(
    LoadComponentsEvent event,
    Emitter<ComponentState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ComponentStatus.loading,
        errorMessage: '',
        clearSelectedComponent: true,
      ),
    );

    final result = await _getComponents(includeInactive: event.includeInactive);

    if (result is Success<List<Component>>) {
      emit(
        state.copyWith(
          status: ComponentStatus.success,
          components: result.data,
          selectedComponentWorkModules: const [],
          isLoadingComponentWorkModules: false,
          errorMessage: '',
          clearSelectedComponent: true,
        ),
      );
      return;
    }

    if (result is FailureResult<List<Component>>) {
      emit(
        state.copyWith(
          status: ComponentStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onLoadComponent(
    LoadComponentEvent event,
    Emitter<ComponentState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ComponentStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _getComponent(event.id);

    if (result is Success<Component>) {
      final selected = result.data;
      emit(
        state.copyWith(
          status: ComponentStatus.success,
          selectedComponent: selected,
          components: _upsertById(state.components, selected),
          selectedComponentWorkModules: const [],
          isLoadingComponentWorkModules: false,
          errorMessage: '',
        ),
      );
      final id = selected.id?.trim() ?? '';
      if (id.isNotEmpty) {
        add(LoadComponentWorkModulesEvent(id));
      }
      return;
    }

    if (result is FailureResult<Component>) {
      emit(
        state.copyWith(
          status: ComponentStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onSetComponentActive(
    SetComponentActiveEvent event,
    Emitter<ComponentState> emit,
  ) async {
    emit(state.copyWith(status: ComponentStatus.loading, errorMessage: ''));

    final result = await _setComponentActive(id: event.id, active: event.active);

    if (result is Success<Component>) {
      final updated = result.data;
      emit(
        state.copyWith(
          status: ComponentStatus.success,
          selectedComponent:
              state.selectedComponent?.id == updated.id ? updated : state.selectedComponent,
          components: _upsertById(state.components, updated),
          errorMessage: '',
        ),
      );

      final selectedId = state.selectedComponent?.id?.trim() ?? '';
      if (selectedId.isNotEmpty && selectedId == updated.id?.trim()) {
        add(LoadComponentWorkModulesEvent(selectedId));
      }
      return;
    }

    if (result is FailureResult<Component>) {
      emit(
        state.copyWith(
          status: ComponentStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onLoadComponentModules(
    LoadComponentWorkModulesEvent event,
    Emitter<ComponentState> emit,
  ) async {
    emit(state.copyWith(isLoadingComponentWorkModules: true, errorMessage: ''));

    final result = await _getComponentModules(event.componentId);

    if (result is Success<List<WorkModule>>) {
      emit(
        state.copyWith(
          isLoadingComponentWorkModules: false,
          selectedComponentWorkModules: List.unmodifiable(result.data),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<List<WorkModule>>) {
      emit(
        state.copyWith(
          isLoadingComponentWorkModules: false,
          status: ComponentStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onAssociateWorkModule(
    AssociateWorkModuleToComponentEvent event,
    Emitter<ComponentState> emit,
  ) async {
    emit(state.copyWith(isUpdatingComponentWorkModules: true, errorMessage: ''));

    final result = await _associateWorkModule(
      workModuleId: event.workModuleId,
      componentId: event.componentId,
    );

    if (result is Success<void>) {
      emit(state.copyWith(isUpdatingComponentWorkModules: false, errorMessage: ''));
      add(LoadComponentWorkModulesEvent(event.componentId));
      return;
    }

    if (result is FailureResult<void>) {
      emit(
        state.copyWith(
          isUpdatingComponentWorkModules: false,
          status: ComponentStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onRemoveWorkModule(
    RemoveWorkModuleFromComponentEvent event,
    Emitter<ComponentState> emit,
  ) async {
    emit(state.copyWith(isUpdatingComponentWorkModules: true, errorMessage: ''));

    final result = await _removeWorkModule(
      workModuleId: event.workModuleId,
      componentId: event.componentId,
    );

    if (result is Success<void>) {
      emit(state.copyWith(isUpdatingComponentWorkModules: false, errorMessage: ''));
      add(LoadComponentWorkModulesEvent(event.componentId));
      return;
    }

    if (result is FailureResult<void>) {
      emit(
        state.copyWith(
          isUpdatingComponentWorkModules: false,
          status: ComponentStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onCreateComponent(
    CreateComponentEvent event,
    Emitter<ComponentState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ComponentStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _createComponent(event.component);

    if (result is Success<Component>) {
      final created = result.data;
      emit(
        state.copyWith(
          status: ComponentStatus.success,
          selectedComponent: created,
          components: _upsertById(state.components, created),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Component>) {
      emit(
        state.copyWith(
          status: ComponentStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onUpdateComponent(
    UpdateComponentEvent event,
    Emitter<ComponentState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ComponentStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _updateComponent(event.component);

    if (result is Success<Component>) {
      final updated = result.data;
      emit(
        state.copyWith(
          status: ComponentStatus.success,
          selectedComponent: updated,
          components: _upsertById(state.components, updated),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Component>) {
      emit(
        state.copyWith(
          status: ComponentStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  List<Component> _upsertById(
    List<Component> current,
    Component component,
  ) {
    final next = List<Component>.from(current);
    final index = next.indexWhere(
      (item) =>
          item.id != null &&
          component.id != null &&
          item.id == component.id,
    );

    if (index >= 0) {
      next[index] = component;
      return List<Component>.unmodifiable(next);
    }

    next.add(component);
    return List<Component>.unmodifiable(next);
  }
}



