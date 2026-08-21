import '../../../../core/error/result.dart';
import '../entities/component.dart';
import '../repositories/component_repository.dart';

class SetComponentActive {
  const SetComponentActive(this._repository);

  final ComponentRepository _repository;

  Future<Result<Component>> call({required String id, required bool active}) {
    return _repository.setIndicatorActive(id: id, active: active);
  }
}



