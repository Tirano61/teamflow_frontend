import '../../../../core/error/result.dart';
import '../entities/work_module.dart';
import '../repositories/work_module_repository.dart';

class SetWorkModuleActive {
  const SetWorkModuleActive(this._repository);

  final WorkModuleRepository _repository;

  Future<Result<WorkModule>> call({required String id, required bool active}) {
    return _repository.setApplicationActive(id: id, active: active);
  }
}



