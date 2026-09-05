import '../../domain/entities/work_module.dart';
import '../../../components/domain/entities/component.dart';

enum WorkModuleStatus { initial, loading, success, error }

class WorkModuleState {
  const WorkModuleState({
    this.status = WorkModuleStatus.initial,
    this.workModules = const [],
    this.selectedWorkModule,
    this.selectedWorkModuleComponents = const [],
    this.isLoadingWorkModuleComponents = false,
    this.isUpdatingWorkModuleComponents = false,
    this.errorMessage = '',
  });

  final WorkModuleStatus status;
  final List<WorkModule> workModules;
  final WorkModule? selectedWorkModule;
  final List<Component> selectedWorkModuleComponents;
  final bool isLoadingWorkModuleComponents;
  final bool isUpdatingWorkModuleComponents;
  final String errorMessage;

  WorkModuleState copyWith({
    WorkModuleStatus? status,
    List<WorkModule>? workModules,
    WorkModule? selectedWorkModule,
    List<Component>? selectedWorkModuleComponents,
    bool? isLoadingWorkModuleComponents,
    bool? isUpdatingWorkModuleComponents,
    bool clearSelectedWorkModule = false,
    String? errorMessage,
  }) {
    return WorkModuleState(
      status: status ?? this.status,
      workModules: workModules ?? this.workModules,
      selectedWorkModule: clearSelectedWorkModule
          ? null
          : selectedWorkModule ?? this.selectedWorkModule,
      selectedWorkModuleComponents:
          selectedWorkModuleComponents ?? this.selectedWorkModuleComponents,
      isLoadingWorkModuleComponents:
          isLoadingWorkModuleComponents ?? this.isLoadingWorkModuleComponents,
      isUpdatingWorkModuleComponents:
          isUpdatingWorkModuleComponents ?? this.isUpdatingWorkModuleComponents,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}


