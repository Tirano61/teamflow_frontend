import '../../../../core/error/result.dart';
import '../entities/discussion.dart';
import '../entities/discussion_changes.dart';
import '../repositories/discussion_repository.dart';

class UpdateDiscussion {
  const UpdateDiscussion(this._repository);

  final DiscussionRepository _repository;

  /// Envia solo los campos presentes en [changes]. Reemplazar el contexto
  /// (`moduleIds`/`componentIds`/`tagIds`) requiere OWNER/ADMIN/DEVELOPER; el
  /// creador `MEMBER` solo puede cambiar `title`/`type`.
  Future<Result<Discussion>> call({
    required String discussionId,
    required DiscussionChanges changes,
  }) {
    return _repository.updateDiscussion(
      discussionId: discussionId,
      changes: changes,
    );
  }
}
