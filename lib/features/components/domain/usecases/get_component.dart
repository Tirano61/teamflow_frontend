import '../../../../core/error/result.dart';
import '../entities/component.dart';
import '../repositories/component_repository.dart';

class GetComponent {
  const GetComponent(this._repository);

  final ComponentRepository _repository;

  Future<Result<Component>> call(String id) {
    return _repository.getIndicatorById(id);
  }
}



