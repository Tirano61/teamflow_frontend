import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../../indicators/domain/entities/indicator.dart';
import '../../domain/entities/application.dart';
import '../../domain/repositories/application_repository.dart';
import '../datasources/application_remote_data_source.dart';
import '../models/application_model.dart';

class ApplicationRepositoryImpl implements ApplicationRepository {
  ApplicationRepositoryImpl({required ApplicationRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final ApplicationRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Application>>> getApplications({
    bool includeInactive = false,
  }) async {
    try {
      final models = await _remoteDataSource.getApplications(
        includeInactive: includeInactive,
      );
      final entities = models.map((model) => model.toEntity()).toList(growable: false);
      return Success<List<Application>>(entities);
    } catch (error) {
      return FailureResult<List<Application>>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Application>> getApplicationById(String id) async {
    try {
      final model = await _remoteDataSource.getApplicationById(id);
      return Success<Application>(model.toEntity());
    } catch (error) {
      return FailureResult<Application>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Application>> createApplication(Application application) async {
    try {
      final model = ApplicationModel.fromEntity(application);
      final created = await _remoteDataSource.createApplication(model);
      return Success<Application>(created.toEntity());
    } catch (error) {
      return FailureResult<Application>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Application>> updateApplication(Application application) async {
    try {
      final model = ApplicationModel.fromEntity(application);
      final updated = await _remoteDataSource.updateApplication(model);
      return Success<Application>(updated.toEntity());
    } catch (error) {
      return FailureResult<Application>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Application>> setApplicationActive({
    required String id,
    required bool active,
  }) async {
    try {
      final updated = await _remoteDataSource.setApplicationActive(
        id: id,
        active: active,
      );
      return Success<Application>(updated.toEntity());
    } catch (error) {
      return FailureResult<Application>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<List<Indicator>>> getIndicatorsByApplicationId(
    String applicationId,
  ) async {
    try {
      final models = await _remoteDataSource.getIndicatorsByApplicationId(
        applicationId,
      );
      final entities = models.map((item) => item.toEntity()).toList(growable: false);
      return Success<List<Indicator>>(entities);
    } catch (error) {
      return FailureResult<List<Indicator>>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> addIndicatorToApplication({
    required String applicationId,
    required String indicatorId,
  }) async {
    try {
      await _remoteDataSource.addIndicatorToApplication(
        applicationId: applicationId,
        indicatorId: indicatorId,
      );
      return Success<void>(null);
    } catch (error) {
      return FailureResult<void>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> removeIndicatorFromApplication({
    required String applicationId,
    required String indicatorId,
  }) async {
    try {
      await _remoteDataSource.removeIndicatorFromApplication(
        applicationId: applicationId,
        indicatorId: indicatorId,
      );
      return Success<void>(null);
    } catch (error) {
      return FailureResult<void>(mapExceptionToFailure(error));
    }
  }
}