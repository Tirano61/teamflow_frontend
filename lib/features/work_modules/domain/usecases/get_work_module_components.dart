import '../../../../core/error/result.dart';
import '../../../components/domain/entities/component.dart';
import '../repositories/work_module_repository.dart';

class GetWorkModuleComponents {
  const GetWorkModuleComponents(this._repository);

  final WorkModuleRepository _repository;

  Future<Result<List<Component>>> call(String workModuleId) {
    return _repository.getIndicatorsByApplicationId(workModuleId);
  }
}



