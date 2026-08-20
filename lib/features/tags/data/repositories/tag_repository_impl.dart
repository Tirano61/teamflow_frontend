import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/tag.dart';
import '../../domain/repositories/tag_repository.dart';
import '../datasources/tag_remote_data_source.dart';
import '../models/tag_model.dart';

class TagRepositoryImpl implements TagRepository {
  TagRepositoryImpl({required TagRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final TagRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Tag>>> getTags({bool includeInactive = false}) async {
    try {
      final models = await _remoteDataSource.getTags(
        includeInactive: includeInactive,
      );
      return Success<List<Tag>>(
        models.map((model) => model.toEntity()).toList(growable: false),
      );
    } catch (error) {
      return FailureResult<List<Tag>>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Tag>> createTag(Tag tag) async {
    try {
      final model = await _remoteDataSource.createTag(TagModel.fromEntity(tag));
      return Success<Tag>(model.toEntity());
    } catch (error) {
      return FailureResult<Tag>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Tag>> updateTag(Tag tag) async {
    try {
      final model = await _remoteDataSource.updateTag(TagModel.fromEntity(tag));
      return Success<Tag>(model.toEntity());
    } catch (error) {
      return FailureResult<Tag>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Tag>> setTagActive({
    required String id,
    required bool active,
  }) async {
    try {
      final model = await _remoteDataSource.setTagActive(
        id: id,
        active: active,
      );
      return Success<Tag>(model.toEntity());
    } catch (error) {
      return FailureResult<Tag>(mapExceptionToFailure(error));
    }
  }
}
