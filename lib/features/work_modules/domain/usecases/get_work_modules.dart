import '../../../../core/error/result.dart';
import '../entities/work_module.dart';
import '../repositories/work_module_repository.dart';

class GetWorkModules {
  const GetWorkModules(this._repository);

  final WorkModuleRepository _repository;

  Future<Result<List<WorkModule>>> call({bool includeInactive = false}) {
    return _repository.getModules(includeInactive: includeInactive);
  }
}


