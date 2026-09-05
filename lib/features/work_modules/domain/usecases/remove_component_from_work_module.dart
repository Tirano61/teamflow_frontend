import '../../../../core/error/result.dart';
import '../repositories/work_module_repository.dart';

class RemoveComponentFromWorkModule {
  const RemoveComponentFromWorkModule(this._repository);

  final WorkModuleRepository _repository;

  Future<Result<void>> call({
    required String workModuleId,
    required String componentId,
  }) {
    return _repository.removeComponentFromModule(
      workModuleId: workModuleId,
      componentId: componentId,
    );
  }
}



