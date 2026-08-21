import '../../../../core/error/result.dart';
import '../entities/component.dart';
import '../repositories/component_repository.dart';

class UpdateComponent {
  const UpdateComponent(this._repository);

  final ComponentRepository _repository;

  Future<Result<Component>> call(Component component) {
    return _repository.updateIndicator(component);
  }
}



