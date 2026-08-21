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



