/// Push FCM recibido por la app (`RemoteMessage.data`), ya validado contra el
/// contrato del backend.
///
/// Los ids que no tienen formato UUID quedan en `null`: nunca se usan para
/// construir rutas ni URLs. Los ids del push no otorgan acceso: la sesion y la
/// organizacion se validan contra `/me/context` antes de usarlos.
class PushNotification {
  const PushNotification({
    required this.type,
    this.recipientUserId,
    this.organizationId,
    this.discussionId,
  });

  /// Tipos de evento de Discussions que define el backend (todos llevan
  /// `organizationId`, `discussionId` y `recipientUserId`).
  static const Set<String> discussionEventTypes = <String>{
    'DISCUSSION_CREATED',
    'DISCUSSION_MESSAGE',
    'DISCUSSION_STATUS_CHANGED',
    'DISCUSSION_ASSIGNMENT_CHANGED',
    'DISCUSSION_MESSAGE_UPDATED',
    'DISCUSSION_MESSAGE_DELETED',
    'DISCUSSION_CONTEXT_CHANGED',
  };

  /// Push de prueba (`POST /workspace/notifications/test`): global, sin
  /// organizacion ni Discussion.
  static const String testType = 'TEST';

  /// Valor crudo de `data.type` (vacio si no vino).
  final String type;

  /// Usuario para el que el backend envio el push a este dispositivo.
  final String? recipientUserId;
  final String? organizationId;
  final String? discussionId;

  bool get isDiscussionEvent => discussionEventTypes.contains(type);

  bool get isTest => type == testType;

  /// Evento de Discussion con todo lo necesario para abrirla: destinatario,
  /// organizacion y Discussion validos.
  bool get targetsDiscussion =>
      isDiscussionEvent &&
      recipientUserId != null &&
      organizationId != null &&
      discussionId != null;
}
