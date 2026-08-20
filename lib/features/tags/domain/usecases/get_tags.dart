import '../../../../core/error/result.dart';
import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

class GetTags {
  const GetTags(this._repository);

  final TagRepository _repository;

  Future<Result<List<Tag>>> call({bool includeInactive = false}) {
    return _repository.getTags(includeInactive: includeInactive);
  }
}
