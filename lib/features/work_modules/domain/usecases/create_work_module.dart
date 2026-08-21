import '../../../../core/error/result.dart';
import '../entities/work_module.dart';
import '../repositories/work_module_repository.dart';

class CreateWorkModule {
  const CreateWorkModule(this._repository);

  final WorkModuleRepository _repository;

  Future<Result<WorkModule>> call(WorkModule workModule) {
    return _repository.createApplication(workModule);
  }
}


