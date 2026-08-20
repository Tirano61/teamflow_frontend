import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/discussion_message.dart';
import '../../domain/entities/discussion_message_page.dart';
import '../../domain/repositories/discussion_message_repository.dart';
import '../datasources/discussion_message_remote_data_source.dart';

class DiscussionMessageRepositoryImpl implements DiscussionMessageRepository {
  DiscussionMessageRepositoryImpl({
    required DiscussionMessageRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final DiscussionMessageRemoteDataSource _remoteDataSource;

  @override
  Future<Result<DiscussionMessagePage>> getMessagesByDiscussion({
    required String discussionId,
    int page = 1,
    int limit = 50,
    DiscussionMessageType? type,
  }) async {
    try {
      final pageModel = await _remoteDataSource.getMessagesByDiscussion(
        discussionId: discussionId,
        page: page,
        limit: limit,
        type: type,
      );
      return Success<DiscussionMessagePage>(pageModel.toEntity());
    } catch (error) {
      return FailureResult<DiscussionMessagePage>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<DiscussionMessage>> createMessage({
    required String discussionId,
    required DiscussionMessageType type,
    required String content,
  }) async {
    try {
      final model = await _remoteDataSource.createMessage(
        discussionId: discussionId,
        type: type,
        content: content,
      );
      return Success<DiscussionMessage>(model.toEntity());
    } catch (error) {
      return FailureResult<DiscussionMessage>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<DiscussionMessage>> createAttachmentMessage({
    required String discussionId,
    required DiscussionMessageType type,
    required String fileName,
    required List<int> fileBytes,
    String? content,
  }) async {
    try {
      final model = await _remoteDataSource.createAttachmentMessage(
        discussionId: discussionId,
        type: type,
        fileName: fileName,
        fileBytes: fileBytes,
        content: content,
      );
      return Success<DiscussionMessage>(model.toEntity());
    } catch (error) {
      return FailureResult<DiscussionMessage>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<DiscussionMessage>> updateMessage({
    required String discussionId,
    required String messageId,
    required String content,
  }) async {
    try {
      final model = await _remoteDataSource.updateMessage(
        discussionId: discussionId,
        messageId: messageId,
        content: content,
      );
      return Success<DiscussionMessage>(model.toEntity());
    } catch (error) {
      return FailureResult<DiscussionMessage>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> deleteMessage({
    required String discussionId,
    required String messageId,
  }) async {
    try {
      await _remoteDataSource.deleteMessage(
        discussionId: discussionId,
        messageId: messageId,
      );
      return const Success<void>(null);
    } catch (error) {
      return FailureResult<void>(mapExceptionToFailure(error));
    }
  }
}
