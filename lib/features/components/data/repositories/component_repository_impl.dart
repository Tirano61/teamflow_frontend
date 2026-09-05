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
  Future<Result<List<Component>>> getComponents({
    bool includeInactive = false,
  }) async {
    try {
      final models = await _remoteDataSource.getComponents(
        includeInactive: includeInactive,
      );
      final entities = models.map((model) => model.toEntity()).toList(growable: false);
      return Success<List<Component>>(entities);
    } catch (error) {
      return FailureResult<List<Component>>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Component>> getComponentById(String id) async {
    try {
      final model = await _remoteDataSource.getComponentById(id);
      return Success<Component>(model.toEntity());
    } catch (error) {
      return FailureResult<Component>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Component>> createComponent(Component component) async {
    try {
      final model = ComponentModel.fromEntity(component);
      final created = await _remoteDataSource.createComponent(model);
      return Success<Component>(created.toEntity());
    } catch (error) {
      return FailureResult<Component>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Component>> updateComponent(Component component) async {
    try {
      final model = ComponentModel.fromEntity(component);
      final updated = await _remoteDataSource.updateComponent(model);
      return Success<Component>(updated.toEntity());
    } catch (error) {
      return FailureResult<Component>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Component>> setComponentActive({
    required String id,
    required bool active,
  }) async {
    try {
      final updated = await _remoteDataSource.setComponentActive(
        id: id,
        active: active,
      );
      return Success<Component>(updated.toEntity());
    } catch (error) {
      return FailureResult<Component>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<List<WorkModule>>> getModulesByComponentId(
    String componentId,
  ) async {
    try {
      final models = await _remoteDataSource.getModulesByComponentId(
        componentId,
      );
      final entities = models.map((item) => item.toEntity()).toList(growable: false);
      return Success<List<WorkModule>>(entities);
    } catch (error) {
      return FailureResult<List<WorkModule>>(mapExceptionToFailure(error));
    }
  }
}
