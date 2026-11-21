import 'package:receive_sharing_intent/receive_sharing_intent.dart';

abstract class ShareIntentDataSource {
  /// `false` en plataformas donde el plugin no tiene implementacion (Web,
  /// escritorio): no se escucha nada ni se invoca el canal nativo.
  bool get isSupported;

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
  bool get isSupported => true;

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

/// Plataformas sin recepcion de contenido compartido (Flutter Web): el plugin
/// `receive_sharing_intent` no tiene implementacion ahi y cualquier llamada
/// termina en `MissingPluginException`.
class ShareIntentNoOpDataSource implements ShareIntentDataSource {
  const ShareIntentNoOpDataSource();

  @override
  bool get isSupported => false;

  @override
  Stream<List<SharedMediaFile>> getMediaStream() =>
      const Stream<List<SharedMediaFile>>.empty();

  @override
  Future<List<SharedMediaFile>> getInitialMedia() async =>
      const <SharedMediaFile>[];

  @override
  Future<void> reset() async {}
}
