import '../../../../core/error/result.dart';
import '../entities/discussion.dart';
import '../repositories/discussion_repository.dart';

class UpdateDiscussion {
  const UpdateDiscussion(this._repository);

  final DiscussionRepository _repository;

  /// [includeContext] envia tambien `moduleIds`/`componentIds`/`tagIds` para
  /// reemplazar el contexto. Solo OWNER/ADMIN/DEVELOPER pueden hacerlo; el
  /// creador `MEMBER` actualiza `title`/`type` sin incluirlo.
  Future<Result<Discussion>> call(
    Discussion discussion, {
    required bool includeContext,
  }) {
    return _repository.updateDiscussion(
      discussion,
      includeContext: includeContext,
    );
  }
}



