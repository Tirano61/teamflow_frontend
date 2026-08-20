import '../../../../core/error/result.dart';
import '../entities/indicator.dart';
import '../repositories/indicator_repository.dart';

class UpdateIndicator {
  const UpdateIndicator(this._repository);

  final IndicatorRepository _repository;

  Future<Result<Indicator>> call(Indicator indicator) {
    return _repository.updateIndicator(indicator);
  }
}
