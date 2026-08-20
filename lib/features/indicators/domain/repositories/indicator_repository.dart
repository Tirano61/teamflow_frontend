import '../../../../core/error/result.dart';
import '../../../applications/domain/entities/application.dart';
import '../entities/indicator.dart';

abstract class IndicatorRepository {
  Future<Result<List<Indicator>>> getIndicators({bool includeInactive = false});

  Future<Result<Indicator>> getIndicatorById(String id);

  Future<Result<Indicator>> createIndicator(Indicator indicator);

  Future<Result<Indicator>> updateIndicator(Indicator indicator);

  Future<Result<Indicator>> setIndicatorActive({
    required String id,
    required bool active,
  });

  Future<Result<List<Application>>> getApplicationsByIndicatorId(String indicatorId);
}
