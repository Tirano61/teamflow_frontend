import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/discussion_message.dart';
import '../models/discussion_message_model.dart';

abstract class DiscussionMessageRemoteDataSource {
  Future<DiscussionMessagePageModel> getMessagesByDiscussion({
    required String discussionId,
    int page = 1,
    int limit = 50,
    DiscussionMessageType? type,
  });

  Future<DiscussionMessageModel> createMessage({
    required String discussionId,
    required DiscussionMessageType type,
    required String content,
  });

  Future<DiscussionMessageModel> createAttachmentMessage({
    required String discussionId,
    required DiscussionMessageType type,
    required String fileName,
    required List<int> fileBytes,
    String? content,
  });

  Future<DiscussionMessageModel> updateMessage({
    required String discussionId,
    required String messageId,
    required String content,
  });

  Future<void> deleteMessage({
    required String discussionId,
    required String messageId,
  });
}

class DiscussionMessageRemoteDataSourceImpl
    implements DiscussionMessageRemoteDataSource {
  DiscussionMessageRemoteDataSourceImpl({required RestClient restClient})
    : _restClient = restClient;

  final RestClient _restClient;

  @override
  Future<DiscussionMessagePageModel> getMessagesByDiscussion({
    required String discussionId,
    int page = 1,
    int limit = 50,
    DiscussionMessageType? type,
  }) async {
    debugPrint(
      '[DISCUSSION] HTTP refresh started - ${_timestampNow()} - '
      'discussionId=$discussionId',
    );

    final response = await _restClient.get<Object?>(
      ApiEndpoints.discussionMessagesByDiscussionId(
        Uri.encodeComponent(discussionId),
      ),
      queryParameters: _buildQueryParameters(
        page: page,
        limit: limit,
        type: type,
      ),
    );

    final model = DiscussionMessagePageModel.fromPayload(
      response.data,
      discussionIdFallback: discussionId,
    );

    debugPrint(
      '[DISCUSSION] HTTP refresh completed - ${_timestampNow()} - '
      'discussionId=$discussionId messages=${model.data.length}',
    );

    return model;
  }

  @override
  Future<DiscussionMessageModel> createMessage({
    required String discussionId,
    required DiscussionMessageType type,
    required String content,
  }) async {
    final payload = DiscussionMessageModel.forCreate(
      type: type,
      content: content,
    );

    final response = await _restClient.post<Object?>(
      ApiEndpoints.discussionMessagesByDiscussionId(
        Uri.encodeComponent(discussionId),
      ),
      body: payload.toCreateJson(),
    );

    return DiscussionMessageModel.fromPayload(
      response.data,
      discussionIdFallback: discussionId,
    );
  }

  @override
  Future<DiscussionMessageModel> createAttachmentMessage({
    required String discussionId,
    required DiscussionMessageType type,
    required String fileName,
    required List<int> fileBytes,
    String? content,
  }) async {
    final normalizedFileName = fileName.trim();
    if (normalizedFileName.isEmpty) {
      throw const ValidationException(
        'El nombre del archivo es obligatorio para subir adjuntos.',
      );
    }

    if (fileBytes.isEmpty) {
      throw const ValidationException(
        'El archivo seleccionado no contiene datos.',
      );
    }

    final payload = DiscussionMessageModel.forAttachmentUpload(
      type: type,
      content: content,
    );

    final endpoint = ApiEndpoints.discussionMessageFilesByDiscussionId(
      Uri.encodeComponent(discussionId),
    );

    RestResponse<Object?> response;
    try {
      response = await _restClient.postMultipart<Object?>(
        endpoint,
        fields: payload.toAttachmentFormFields(),
        fileField: 'file',
        fileBytes: fileBytes,
        fileName: normalizedFileName,
      );
    } on NetworkException catch (error) {
      throw NetworkException(
        '${error.message}\n\n'
        'Diagnostico web: si este mismo archivo funciona en tablet, '
        'el problema suele ser CORS/preflight del endpoint de archivos '
        '(OPTIONS/POST). Endpoint: $endpoint',
      );
    }

    return DiscussionMessageModel.fromPayload(
      response.data,
      discussionIdFallback: discussionId,
    );
  }

  @override
  Future<DiscussionMessageModel> updateMessage({
    required String discussionId,
    required String messageId,
    required String content,
  }) async {
    if (messageId.trim().isEmpty) {
      throw const ValidationException('A message id is required to update it.');
    }

    final payload = DiscussionMessageModel.forUpdate(content: content);

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.discussionMessageByIds(
        Uri.encodeComponent(discussionId),
        Uri.encodeComponent(messageId),
      ),
      body: payload.toUpdateJson(),
    );

    return DiscussionMessageModel.fromPayload(
      response.data,
      discussionIdFallback: discussionId,
    );
  }

  @override
  Future<void> deleteMessage({
    required String discussionId,
    required String messageId,
  }) async {
    if (messageId.trim().isEmpty) {
      throw const ValidationException('A message id is required to delete it.');
    }

    await _restClient.delete<Object?>(
      ApiEndpoints.discussionMessageByIds(
        Uri.encodeComponent(discussionId),
        Uri.encodeComponent(messageId),
      ),
    );
  }

  QueryParams _buildQueryParameters({
    required int page,
    required int limit,
    DiscussionMessageType? type,
  }) {
    final params = <String, dynamic>{'page': page, 'limit': limit};

    if (type != null && type != DiscussionMessageType.unknown) {
      params['type'] = type.apiValue;
    }

    return params;
  }

  String _timestampNow() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');
    return '$hh:$mm:$ss.$ms';
  }
}
