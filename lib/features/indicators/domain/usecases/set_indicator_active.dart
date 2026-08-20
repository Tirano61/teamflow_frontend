import '../../../../core/error/result.dart';
import '../entities/indicator.dart';
import '../repositories/indicator_repository.dart';

class SetIndicatorActive {
  const SetIndicatorActive(this._repository);

  final IndicatorRepository _repository;

  Future<Result<Indicator>> call({required String id, required bool active}) {
    return _repository.setIndicatorActive(id: id, active: active);
  }
}
