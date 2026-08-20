import '../../../../core/error/result.dart';
import '../entities/application.dart';
import '../repositories/application_repository.dart';

class UpdateApplication {
  const UpdateApplication(this._repository);

  final ApplicationRepository _repository;

  Future<Result<Application>> call(Application application) {
    return _repository.updateApplication(application);
  }
}