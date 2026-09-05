import '../../../../core/error/result.dart';
import '../entities/component.dart';
import '../repositories/component_repository.dart';

class GetComponents {
  const GetComponents(this._repository);

  final ComponentRepository _repository;

  Future<Result<List<Component>>> call({bool includeInactive = false}) {
    return _repository.getComponents(includeInactive: includeInactive);
  }
}



