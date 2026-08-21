import '../../../../core/error/result.dart';
import '../../../components/domain/entities/component.dart';
import '../entities/work_module.dart';

abstract class WorkModuleRepository {
  Future<Result<List<WorkModule>>> getApplications({bool includeInactive = false});

  Future<Result<WorkModule>> getApplicationById(String id);

  Future<Result<WorkModule>> createApplication(WorkModule workModule);

  Future<Result<WorkModule>> updateApplication(WorkModule workModule);

  Future<Result<WorkModule>> setApplicationActive({
    required String id,
    required bool active,
  });

  Future<Result<List<Component>>> getIndicatorsByApplicationId(String workModuleId);

  Future<Result<void>> addIndicatorToApplication({
    required String workModuleId,
    required String componentId,
  });

  Future<Result<void>> removeIndicatorFromApplication({
    required String workModuleId,
    required String componentId,
  });
}


