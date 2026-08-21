import '../../../../core/error/result.dart';
import '../../../work_modules/domain/entities/work_module.dart';
import '../entities/component.dart';

abstract class ComponentRepository {
  Future<Result<List<Component>>> getIndicators({bool includeInactive = false});

  Future<Result<Component>> getIndicatorById(String id);

  Future<Result<Component>> createIndicator(Component component);

  Future<Result<Component>> updateIndicator(Component component);

  Future<Result<Component>> setIndicatorActive({
    required String id,
    required bool active,
  });

  Future<Result<List<WorkModule>>> getApplicationsByIndicatorId(String componentId);
}



