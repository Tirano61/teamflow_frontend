import '../../domain/entities/application.dart';

sealed class ApplicationEvent {
  const ApplicationEvent();
}

class LoadApplicationsEvent extends ApplicationEvent {
  const LoadApplicationsEvent({this.includeInactive = false});

  final bool includeInactive;
}

class LoadApplicationEvent extends ApplicationEvent {
  const LoadApplicationEvent(this.id);

  final String id;
}

class CreateApplicationEvent extends ApplicationEvent {
  const CreateApplicationEvent(this.application);

  final Application application;
}

class UpdateApplicationEvent extends ApplicationEvent {
  const UpdateApplicationEvent(this.application);

  final Application application;
}

class SetApplicationActiveEvent extends ApplicationEvent {
  const SetApplicationActiveEvent({required this.id, required this.active});

  final String id;
  final bool active;
}

class LoadApplicationIndicatorsEvent extends ApplicationEvent {
  const LoadApplicationIndicatorsEvent(this.applicationId);

  final String applicationId;
}

class AssociateIndicatorEvent extends ApplicationEvent {
  const AssociateIndicatorEvent({
    required this.applicationId,
    required this.indicatorId,
  });

  final String applicationId;
  final String indicatorId;
}

class RemoveAssociatedIndicatorEvent extends ApplicationEvent {
  const RemoveAssociatedIndicatorEvent({
    required this.applicationId,
    required this.indicatorId,
  });

  final String applicationId;
  final String indicatorId;
}