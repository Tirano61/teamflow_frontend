import '../../domain/entities/indicator.dart';

sealed class IndicatorEvent {
  const IndicatorEvent();
}

class LoadIndicatorsEvent extends IndicatorEvent {
  const LoadIndicatorsEvent({this.includeInactive = false});

  final bool includeInactive;
}

class LoadIndicatorEvent extends IndicatorEvent {
  const LoadIndicatorEvent(this.id);

  final String id;
}

class CreateIndicatorEvent extends IndicatorEvent {
  const CreateIndicatorEvent(this.indicator);

  final Indicator indicator;
}

class UpdateIndicatorEvent extends IndicatorEvent {
  const UpdateIndicatorEvent(this.indicator);

  final Indicator indicator;
}

class SetIndicatorActiveEvent extends IndicatorEvent {
  const SetIndicatorActiveEvent({required this.id, required this.active});

  final String id;
  final bool active;
}

class LoadIndicatorApplicationsEvent extends IndicatorEvent {
  const LoadIndicatorApplicationsEvent(this.indicatorId);

  final String indicatorId;
}
