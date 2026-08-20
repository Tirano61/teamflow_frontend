import '../../domain/entities/application.dart';
import '../../../indicators/domain/entities/indicator.dart';

enum ApplicationStatus { initial, loading, success, error }

class ApplicationState {
  const ApplicationState({
    this.status = ApplicationStatus.initial,
    this.applications = const [],
    this.selectedApplication,
    this.selectedApplicationIndicators = const [],
    this.isLoadingApplicationIndicators = false,
    this.isUpdatingApplicationIndicators = false,
    this.errorMessage = '',
  });

  final ApplicationStatus status;
  final List<Application> applications;
  final Application? selectedApplication;
  final List<Indicator> selectedApplicationIndicators;
  final bool isLoadingApplicationIndicators;
  final bool isUpdatingApplicationIndicators;
  final String errorMessage;

  ApplicationState copyWith({
    ApplicationStatus? status,
    List<Application>? applications,
    Application? selectedApplication,
    List<Indicator>? selectedApplicationIndicators,
    bool? isLoadingApplicationIndicators,
    bool? isUpdatingApplicationIndicators,
    bool clearSelectedApplication = false,
    String? errorMessage,
  }) {
    return ApplicationState(
      status: status ?? this.status,
      applications: applications ?? this.applications,
      selectedApplication: clearSelectedApplication
          ? null
          : selectedApplication ?? this.selectedApplication,
      selectedApplicationIndicators:
          selectedApplicationIndicators ?? this.selectedApplicationIndicators,
      isLoadingApplicationIndicators:
          isLoadingApplicationIndicators ?? this.isLoadingApplicationIndicators,
      isUpdatingApplicationIndicators:
          isUpdatingApplicationIndicators ?? this.isUpdatingApplicationIndicators,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}