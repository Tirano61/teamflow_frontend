import '../../../../core/error/result.dart';
import '../repositories/application_repository.dart';

class RemoveIndicatorFromApplication {
  const RemoveIndicatorFromApplication(this._repository);

  final ApplicationRepository _repository;

  Future<Result<void>> call({
    required String applicationId,
    required String indicatorId,
  }) {
    return _repository.removeIndicatorFromApplication(
      applicationId: applicationId,
      indicatorId: indicatorId,
    );
  }
}
