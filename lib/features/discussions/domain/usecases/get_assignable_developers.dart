import '../../../../core/error/result.dart';
import '../entities/discussion_developer.dart';
import '../repositories/discussion_repository.dart';

class GetAssignableDevelopers {
  const GetAssignableDevelopers(this._repository);

  final DiscussionRepository _repository;

  Future<Result<List<AssignableDeveloper>>> call() {
    return _repository.getAssignableDevelopers();
  }
}
