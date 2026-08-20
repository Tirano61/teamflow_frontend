import '../../../../core/error/result.dart';
import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

class CreateTag {
  const CreateTag(this._repository);

  final TagRepository _repository;

  Future<Result<Tag>> call(Tag tag) {
    return _repository.createTag(tag);
  }
}
