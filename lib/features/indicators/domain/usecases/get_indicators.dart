import '../../../../core/error/result.dart';
import '../entities/indicator.dart';
import '../repositories/indicator_repository.dart';

class GetIndicators {
  const GetIndicators(this._repository);

  final IndicatorRepository _repository;

  Future<Result<List<Indicator>>> call({bool includeInactive = false}) {
    return _repository.getIndicators(includeInactive: includeInactive);
  }
}
