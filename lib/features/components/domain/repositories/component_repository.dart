import '../../../../core/error/result.dart';
import '../../../work_modules/domain/entities/work_module.dart';
import '../entities/component.dart';

abstract class ComponentRepository {
  Future<Result<List<Component>>> getComponents({bool includeInactive = false});

  Future<Result<Component>> getComponentById(String id);

  Future<Result<Component>> createComponent(Component component);

  Future<Result<Component>> updateComponent(Component component);

  Future<Result<Component>> setComponentActive({
    required String id,
    required bool active,
  });

  Future<Result<List<WorkModule>>> getModulesByComponentId(String componentId);
}
