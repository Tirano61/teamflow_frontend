import '../../../../core/error/result.dart';
import '../entities/tag.dart';

abstract class TagRepository {
  Future<Result<List<Tag>>> getTags({bool includeInactive = false});

  Future<Result<Tag>> createTag(Tag tag);

  Future<Result<Tag>> updateTag(Tag tag);

  Future<Result<Tag>> setTagActive({required String id, required bool active});
}
