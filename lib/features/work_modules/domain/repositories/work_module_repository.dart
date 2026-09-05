import '../../../../core/error/result.dart';
import '../../../components/domain/entities/component.dart';
import '../entities/work_module.dart';

abstract class WorkModuleRepository {
  Future<Result<List<WorkModule>>> getModules({bool includeInactive = false});

  Future<Result<WorkModule>> getModuleById(String id);

  Future<Result<WorkModule>> createModule(WorkModule workModule);

  Future<Result<WorkModule>> updateModule(WorkModule workModule);

  Future<Result<WorkModule>> setModuleActive({
    required String id,
    required bool active,
  });

  Future<Result<List<Component>>> getComponentsByModuleId(String workModuleId);

  Future<Result<void>> addComponentToModule({
    required String workModuleId,
    required String componentId,
  });

  Future<Result<void>> removeComponentFromModule({
    required String workModuleId,
    required String componentId,
  });
}
