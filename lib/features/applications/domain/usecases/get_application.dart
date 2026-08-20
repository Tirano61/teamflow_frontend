import '../../../../core/error/result.dart';
import '../entities/application.dart';
import '../repositories/application_repository.dart';

class GetApplication {
  const GetApplication(this._repository);

  final ApplicationRepository _repository;

  Future<Result<Application>> call(String id) {
    return _repository.getApplicationById(id);
  }
}