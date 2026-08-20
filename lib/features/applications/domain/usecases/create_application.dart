import '../../../../core/error/result.dart';
import '../entities/application.dart';
import '../repositories/application_repository.dart';

class CreateApplication {
  const CreateApplication(this._repository);

  final ApplicationRepository _repository;

  Future<Result<Application>> call(Application application) {
    return _repository.createApplication(application);
  }
}