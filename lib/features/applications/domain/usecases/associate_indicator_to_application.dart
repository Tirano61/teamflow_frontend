import '../../../../core/error/result.dart';
import '../repositories/application_repository.dart';

class AssociateIndicatorToApplication {
  const AssociateIndicatorToApplication(this._repository);

  final ApplicationRepository _repository;

  Future<Result<void>> call({
    required String applicationId,
    required String indicatorId,
  }) {
    return _repository.addIndicatorToApplication(
      applicationId: applicationId,
      indicatorId: indicatorId,
    );
  }
}
