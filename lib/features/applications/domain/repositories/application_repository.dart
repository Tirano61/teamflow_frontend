import '../../../../core/error/result.dart';
import '../../../indicators/domain/entities/indicator.dart';
import '../entities/application.dart';

abstract class ApplicationRepository {
  Future<Result<List<Application>>> getApplications({bool includeInactive = false});

  Future<Result<Application>> getApplicationById(String id);

  Future<Result<Application>> createApplication(Application application);

  Future<Result<Application>> updateApplication(Application application);

  Future<Result<Application>> setApplicationActive({
    required String id,
    required bool active,
  });

  Future<Result<List<Indicator>>> getIndicatorsByApplicationId(String applicationId);

  Future<Result<void>> addIndicatorToApplication({
    required String applicationId,
    required String indicatorId,
  });

  Future<Result<void>> removeIndicatorFromApplication({
    required String applicationId,
    required String indicatorId,
  });
}