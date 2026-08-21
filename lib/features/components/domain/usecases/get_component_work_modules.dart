import '../../../../core/error/result.dart';
import '../../../work_modules/domain/entities/work_module.dart';
import '../repositories/component_repository.dart';

class GetComponentWorkModules {
  const GetComponentWorkModules(this._repository);

  final ComponentRepository _repository;

  Future<Result<List<WorkModule>>> call(String componentId) {
    return _repository.getApplicationsByIndicatorId(componentId);
  }
}



