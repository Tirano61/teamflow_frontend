import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../../work_modules/domain/entities/work_module.dart';
import '../../domain/entities/component.dart';
import '../../domain/repositories/component_repository.dart';
import '../datasources/component_remote_data_source.dart';
import '../models/component_model.dart';

class ComponentRepositoryImpl implements ComponentRepository {
  ComponentRepositoryImpl({required ComponentRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final ComponentRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Component>>> getIndicators({
    bool includeInactive = false,
  }) async {
    try {
      final models = await _remoteDataSource.getIndicators(
        includeInactive: includeInactive,
      );
      final entities = models.map((model) => model.toEntity()).toList(growable: false);
      return Success<List<Component>>(entities);
    } catch (error) {
      return FailureResult<List<Component>>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Component>> getIndicatorById(String id) async {
    try {
      final model = await _remoteDataSource.getIndicatorById(id);
      return Success<Component>(model.toEntity());
    } catch (error) {
      return FailureResult<Component>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Component>> createIndicator(Component component) async {
    try {
      final model = ComponentModel.fromEntity(component);
      final created = await _remoteDataSource.createIndicator(model);
      return Success<Component>(created.toEntity());
    } catch (error) {
      return FailureResult<Component>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Component>> updateIndicator(Component component) async {
    try {
      final model = ComponentModel.fromEntity(component);
      final updated = await _remoteDataSource.updateIndicator(model);
      return Success<Component>(updated.toEntity());
    } catch (error) {
      return FailureResult<Component>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Component>> setIndicatorActive({
    required String id,
    required bool active,
  }) async {
    try {
      final updated = await _remoteDataSource.setIndicatorActive(
        id: id,
        active: active,
      );
      return Success<Component>(updated.toEntity());
    } catch (error) {
      return FailureResult<Component>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<List<WorkModule>>> getApplicationsByIndicatorId(
    String componentId,
  ) async {
    try {
      final models = await _remoteDataSource.getApplicationsByIndicatorId(
        componentId,
      );
      final entities = models.map((item) => item.toEntity()).toList(growable: false);
      return Success<List<WorkModule>>(entities);
    } catch (error) {
      return FailureResult<List<WorkModule>>(mapExceptionToFailure(error));
    }
  }
}



