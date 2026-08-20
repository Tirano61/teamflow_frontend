import '../../../../core/error/result.dart';
import '../entities/application.dart';
import '../repositories/application_repository.dart';

class SetApplicationActive {
  const SetApplicationActive(this._repository);

  final ApplicationRepository _repository;

  Future<Result<Application>> call({required String id, required bool active}) {
    return _repository.setApplicationActive(id: id, active: active);
  }
}
