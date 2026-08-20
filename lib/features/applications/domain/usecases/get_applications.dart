import '../../../../core/error/result.dart';
import '../entities/application.dart';
import '../repositories/application_repository.dart';

class GetApplications {
  const GetApplications(this._repository);

  final ApplicationRepository _repository;

  Future<Result<List<Application>>> call({bool includeInactive = false}) {
    return _repository.getApplications(includeInactive: includeInactive);
  }
}