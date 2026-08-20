import '../../../../core/error/result.dart';
import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

class SetTagActive {
  const SetTagActive(this._repository);

  final TagRepository _repository;

  Future<Result<Tag>> call({required String id, required bool active}) {
    return _repository.setTagActive(id: id, active: active);
  }
}
