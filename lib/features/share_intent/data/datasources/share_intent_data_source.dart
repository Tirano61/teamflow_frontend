import 'package:receive_sharing_intent/receive_sharing_intent.dart';

abstract class ShareIntentDataSource {
  Stream<List<SharedMediaFile>> getMediaStream();

  Future<List<SharedMediaFile>> getInitialMedia();

  Future<void> reset();
}

class ShareIntentDataSourceImpl implements ShareIntentDataSource {
  ShareIntentDataSourceImpl({ReceiveSharingIntent? receiveSharingIntent})
    : _receiveSharingIntent =
          receiveSharingIntent ?? ReceiveSharingIntent.instance;

  final ReceiveSharingIntent _receiveSharingIntent;

  @override
  Stream<List<SharedMediaFile>> getMediaStream() {
    return _receiveSharingIntent.getMediaStream();
  }

  @override
  Future<List<SharedMediaFile>> getInitialMedia() {
    return _receiveSharingIntent.getInitialMedia();
  }

  @override
  Future<void> reset() {
    return _receiveSharingIntent.reset();
  }
}
