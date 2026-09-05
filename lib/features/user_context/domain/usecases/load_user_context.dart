import '../../../../core/error/result.dart';
import '../entities/user_context.dart';
import '../repositories/user_context_repository.dart';

class LoadUserContext {
  const LoadUserContext(this._repository);

  final UserContextRepository _repository;

  Future<Result<UserContext>> call() {
    return _repository.loadUserContext();
  }
}
