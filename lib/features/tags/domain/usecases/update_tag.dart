import '../../../../core/error/result.dart';
import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

class UpdateTag {
  const UpdateTag(this._repository);

  final TagRepository _repository;

  Future<Result<Tag>> call(Tag tag) {
    return _repository.updateTag(tag);
  }
}
