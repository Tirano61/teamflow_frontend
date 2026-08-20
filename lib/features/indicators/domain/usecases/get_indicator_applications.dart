import '../../../../core/error/result.dart';
import '../../../applications/domain/entities/application.dart';
import '../repositories/indicator_repository.dart';

class GetIndicatorApplications {
  const GetIndicatorApplications(this._repository);

  final IndicatorRepository _repository;

  Future<Result<List<Application>>> call(String indicatorId) {
    return _repository.getApplicationsByIndicatorId(indicatorId);
  }
}
