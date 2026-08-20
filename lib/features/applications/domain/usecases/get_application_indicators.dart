import '../../../../core/error/result.dart';
import '../../../indicators/domain/entities/indicator.dart';
import '../repositories/application_repository.dart';

class GetApplicationIndicators {
  const GetApplicationIndicators(this._repository);

  final ApplicationRepository _repository;

  Future<Result<List<Indicator>>> call(String applicationId) {
    return _repository.getIndicatorsByApplicationId(applicationId);
  }
}
