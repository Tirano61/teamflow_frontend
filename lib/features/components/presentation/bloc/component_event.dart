import '../../domain/entities/component.dart';

sealed class ComponentEvent {
  const ComponentEvent();
}

class LoadComponentsEvent extends ComponentEvent {
  const LoadComponentsEvent({this.includeInactive = false});

  final bool includeInactive;
}

class LoadComponentEvent extends ComponentEvent {
  const LoadComponentEvent(this.id);

  final String id;
}

class CreateComponentEvent extends ComponentEvent {
  const CreateComponentEvent(this.component);

  final Component component;
}

class UpdateComponentEvent extends ComponentEvent {
  const UpdateComponentEvent(this.component);

  final Component component;
}

class SetComponentActiveEvent extends ComponentEvent {
  const SetComponentActiveEvent({required this.id, required this.active});

  final String id;
  final bool active;
}

class LoadComponentWorkModulesEvent extends ComponentEvent {
  const LoadComponentWorkModulesEvent(this.componentId);

  final String componentId;
}

/// Asocia un WorkModule al Component. Es la misma relacion ManyToMany que se
/// administra desde el WorkModule: solo cambia la perspectiva de la UI.
class AssociateWorkModuleToComponentEvent extends ComponentEvent {
  const AssociateWorkModuleToComponentEvent({
    required this.componentId,
    required this.workModuleId,
  });

  final String componentId;
  final String workModuleId;
}

/// Quita la relacion entre un WorkModule y el Component. No elimina ninguno de
/// los dos recursos.
class RemoveWorkModuleFromComponentEvent extends ComponentEvent {
  const RemoveWorkModuleFromComponentEvent({
    required this.componentId,
    required this.workModuleId,
  });

  final String componentId;
  final String workModuleId;
}
