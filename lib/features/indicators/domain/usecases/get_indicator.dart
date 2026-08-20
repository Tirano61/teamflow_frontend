import '../../../../core/error/result.dart';
import '../entities/indicator.dart';
import '../repositories/indicator_repository.dart';

class GetIndicator {
  const GetIndicator(this._repository);

  final IndicatorRepository _repository;

  Future<Result<Indicator>> call(String id) {
    return _repository.getIndicatorById(id);
  }
}
