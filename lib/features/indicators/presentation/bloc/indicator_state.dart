import '../../domain/entities/indicator.dart';
import '../../../applications/domain/entities/application.dart';

enum IndicatorStatus { initial, loading, success, error }

class IndicatorState {
  const IndicatorState({
    this.status = IndicatorStatus.initial,
    this.indicators = const [],
    this.selectedIndicator,
    this.selectedIndicatorApplications = const [],
    this.isLoadingIndicatorApplications = false,
    this.errorMessage = '',
  });

  final IndicatorStatus status;
  final List<Indicator> indicators;
  final Indicator? selectedIndicator;
  final List<Application> selectedIndicatorApplications;
  final bool isLoadingIndicatorApplications;
  final String errorMessage;

  IndicatorState copyWith({
    IndicatorStatus? status,
    List<Indicator>? indicators,
    Indicator? selectedIndicator,
    List<Application>? selectedIndicatorApplications,
    bool? isLoadingIndicatorApplications,
    bool clearSelectedIndicator = false,
    String? errorMessage,
  }) {
    return IndicatorState(
      status: status ?? this.status,
      indicators: indicators ?? this.indicators,
      selectedIndicator:
          clearSelectedIndicator ? null : selectedIndicator ?? this.selectedIndicator,
      selectedIndicatorApplications:
          selectedIndicatorApplications ?? this.selectedIndicatorApplications,
      isLoadingIndicatorApplications:
          isLoadingIndicatorApplications ?? this.isLoadingIndicatorApplications,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
