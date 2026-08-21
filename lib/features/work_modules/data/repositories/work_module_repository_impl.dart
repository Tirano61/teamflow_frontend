import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../../components/domain/entities/component.dart';
import '../../domain/entities/work_module.dart';
import '../../domain/repositories/work_module_repository.dart';
import '../datasources/work_module_remote_data_source.dart';
import '../models/work_module_model.dart';

class WorkModuleRepositoryImpl implements WorkModuleRepository {
  WorkModuleRepositoryImpl({required WorkModuleRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final WorkModuleRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<WorkModule>>> getApplications({
    bool includeInactive = false,
  }) async {
    try {
      final models = await _remoteDataSource.getApplications(
        includeInactive: includeInactive,
      );
      final entities = models.map((model) => model.toEntity()).toList(growable: false);
      return Success<List<WorkModule>>(entities);
    } catch (error) {
      return FailureResult<List<WorkModule>>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<WorkModule>> getApplicationById(String id) async {
    try {
      final model = await _remoteDataSource.getApplicationById(id);
      return Success<WorkModule>(model.toEntity());
    } catch (error) {
      return FailureResult<WorkModule>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<WorkModule>> createApplication(WorkModule workModule) async {
    try {
      final model = WorkModuleModel.fromEntity(workModule);
      final created = await _remoteDataSource.createApplication(model);
      return Success<WorkModule>(created.toEntity());
    } catch (error) {
      return FailureResult<WorkModule>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<WorkModule>> updateApplication(WorkModule workModule) async {
    try {
      final model = WorkModuleModel.fromEntity(workModule);
      final updated = await _remoteDataSource.updateApplication(model);
      return Success<WorkModule>(updated.toEntity());
    } catch (error) {
      return FailureResult<WorkModule>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<WorkModule>> setApplicationActive({
    required String id,
    required bool active,
  }) async {
    try {
      final updated = await _remoteDataSource.setApplicationActive(
        id: id,
        active: active,
      );
      return Success<WorkModule>(updated.toEntity());
    } catch (error) {
      return FailureResult<WorkModule>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<List<Component>>> getIndicatorsByApplicationId(
    String workModuleId,
  ) async {
    try {
      final models = await _remoteDataSource.getIndicatorsByApplicationId(
        workModuleId,
      );
      final entities = models.map((item) => item.toEntity()).toList(growable: false);
      return Success<List<Component>>(entities);
    } catch (error) {
      return FailureResult<List<Component>>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> addIndicatorToApplication({
    required String workModuleId,
    required String componentId,
  }) async {
    try {
      await _remoteDataSource.addIndicatorToApplication(
        workModuleId: workModuleId,
        componentId: componentId,
      );
      return Success<void>(null);
    } catch (error) {
      return FailureResult<void>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> removeIndicatorFromApplication({
    required String workModuleId,
    required String componentId,
  }) async {
    try {
      await _remoteDataSource.removeIndicatorFromApplication(
        workModuleId: workModuleId,
        componentId: componentId,
      );
      return Success<void>(null);
    } catch (error) {
      return FailureResult<void>(mapExceptionToFailure(error));
    }
  }
}


