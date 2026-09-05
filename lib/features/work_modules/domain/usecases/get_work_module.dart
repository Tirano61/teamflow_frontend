import '../../../../core/error/result.dart';
import '../entities/work_module.dart';
import '../repositories/work_module_repository.dart';

class GetWorkModule {
  const GetWorkModule(this._repository);

  final WorkModuleRepository _repository;

  Future<Result<WorkModule>> call(String id) {
    return _repository.getModuleById(id);
  }
}


