import '../../domain/entities/work_module.dart';

sealed class WorkModuleEvent {
  const WorkModuleEvent();
}

class LoadWorkModulesEvent extends WorkModuleEvent {
  const LoadWorkModulesEvent({this.includeInactive = false});

  final bool includeInactive;
}

class LoadWorkModuleEvent extends WorkModuleEvent {
  const LoadWorkModuleEvent(this.id);

  final String id;
}

class CreateWorkModuleEvent extends WorkModuleEvent {
  const CreateWorkModuleEvent(this.workModule);

  final WorkModule workModule;
}

class UpdateWorkModuleEvent extends WorkModuleEvent {
  const UpdateWorkModuleEvent(this.workModule);

  final WorkModule workModule;
}

class SetWorkModuleActiveEvent extends WorkModuleEvent {
  const SetWorkModuleActiveEvent({required this.id, required this.active});

  final String id;
  final bool active;
}

class LoadWorkModuleComponentsEvent extends WorkModuleEvent {
  const LoadWorkModuleComponentsEvent(this.workModuleId);

  final String workModuleId;
}

class AssociateComponentEvent extends WorkModuleEvent {
  const AssociateComponentEvent({
    required this.workModuleId,
    required this.componentId,
  });

  final String workModuleId;
  final String componentId;
}

class RemoveAssociatedComponentEvent extends WorkModuleEvent {
  const RemoveAssociatedComponentEvent({
    required this.workModuleId,
    required this.componentId,
  });

  final String workModuleId;
  final String componentId;
}


