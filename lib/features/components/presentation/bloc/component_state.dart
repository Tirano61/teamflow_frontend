import '../../domain/entities/component.dart';
import '../../../work_modules/domain/entities/work_module.dart';

enum ComponentStatus { initial, loading, success, error }

class ComponentState {
  const ComponentState({
    this.status = ComponentStatus.initial,
    this.components = const [],
    this.selectedComponent,
    this.selectedComponentWorkModules = const [],
    this.isLoadingComponentWorkModules = false,
    this.errorMessage = '',
  });

  final ComponentStatus status;
  final List<Component> components;
  final Component? selectedComponent;
  final List<WorkModule> selectedComponentWorkModules;
  final bool isLoadingComponentWorkModules;
  final String errorMessage;

  ComponentState copyWith({
    ComponentStatus? status,
    List<Component>? components,
    Component? selectedComponent,
    List<WorkModule>? selectedComponentWorkModules,
    bool? isLoadingComponentWorkModules,
    bool clearSelectedIndicator = false,
    String? errorMessage,
  }) {
    return ComponentState(
      status: status ?? this.status,
      components: components ?? this.components,
      selectedComponent:
          clearSelectedIndicator ? null : selectedComponent ?? this.selectedComponent,
      selectedComponentWorkModules:
          selectedComponentWorkModules ?? this.selectedComponentWorkModules,
      isLoadingComponentWorkModules:
          isLoadingComponentWorkModules ?? this.isLoadingComponentWorkModules,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}



