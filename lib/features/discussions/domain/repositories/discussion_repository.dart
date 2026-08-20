import '../../../../core/error/result.dart';
import '../entities/discussion.dart';
import '../entities/discussion_developer.dart';
import '../entities/discussion_filters.dart';
import '../entities/discussion_page.dart';

abstract class DiscussionRepository {
  Future<Result<DiscussionPage>> getDiscussions({
    DiscussionFilters filters = const DiscussionFilters(),
  });

  Future<Result<Discussion>> getDiscussionById(String id);

  Future<Result<DiscussionReadState>> markDiscussionAsRead(String discussionId);

  Future<Result<Discussion>> createDiscussion(Discussion discussion);

  Future<Result<Discussion>> updateDiscussion(Discussion discussion);

  Future<Result<Discussion>> updateDiscussionStatus({
    required String discussionId,
    required DiscussionRecordStatus status,
  });

  Future<Result<List<AssignableDeveloper>>> getAssignableDevelopers();

  Future<Result<Discussion>> addDiscussionAssignments({
    required String discussionId,
    required List<String> developerUserIds,
  });

  Future<Result<Discussion>> replaceDiscussionAssignments({
    required String discussionId,
    required List<String> developerUserIds,
  });

  Future<Result<Discussion>> removeDiscussionAssignment({
    required String discussionId,
    required String developerUserId,
  });
}
