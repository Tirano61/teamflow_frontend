import '../../../../core/error/result.dart';
import '../repositories/work_module_repository.dart';

class AssociateComponentToWorkModule {
  const AssociateComponentToWorkModule(this._repository);

  final WorkModuleRepository _repository;

  Future<Result<void>> call({
    required String workModuleId,
    required String componentId,
  }) {
    return _repository.addIndicatorToApplication(
      workModuleId: workModuleId,
      componentId: componentId,
    );
  }
}



