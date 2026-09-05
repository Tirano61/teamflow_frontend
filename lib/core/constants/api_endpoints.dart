/// Rutas de la API TeamFlow.
///
/// Hay dos familias de endpoints:
/// - Tenant: `/organizations/{organizationId}/workspace/...`
/// - Globales: `/workspace/...` (no pertenecen a una organizacion)
class ApiEndpoints {
  const ApiEndpoints._();

  // ---------------------------------------------------------------------------
  // Auth (publico)
  // ---------------------------------------------------------------------------

  static const String authLogin = '/auth/login';

  // ---------------------------------------------------------------------------
  // Globales (autenticados, sin organizationId)
  // ---------------------------------------------------------------------------

  static const String globalWorkspace = '/workspace';

  static const String devices = '$globalWorkspace/devices';

  static const String notifications = '$globalWorkspace/notifications';

  static const String notificationsTest = '$notifications/test';

  // ---------------------------------------------------------------------------
  // Base tenant
  // ---------------------------------------------------------------------------

  static const String organizations = '/organizations';

  static String organizationById(String organizationId) =>
      '$organizations/${Uri.encodeComponent(organizationId)}';

  /// `/organizations/{organizationId}/workspace`
  static String workspace(String organizationId) =>
      '${organizationById(organizationId)}/workspace';

  // ---------------------------------------------------------------------------
  // Modules
  // ---------------------------------------------------------------------------

  static String modules(String organizationId) =>
      '${workspace(organizationId)}/modules';

  static String modulesAll(String organizationId) =>
      '${modules(organizationId)}/all';

  static String moduleById(String organizationId, String moduleId) =>
      '${modules(organizationId)}/$moduleId';

  static String moduleAllById(String organizationId, String moduleId) =>
      '${modulesAll(organizationId)}/$moduleId';

  static String moduleActiveById(String organizationId, String moduleId) =>
      '${moduleById(organizationId, moduleId)}/active';

  /// `/organizations/{organizationId}/workspace/modules/{moduleId}/components`
  static String moduleComponents(String organizationId, String moduleId) =>
      '${moduleById(organizationId, moduleId)}/components';

  static String moduleComponentByIds(
    String organizationId,
    String moduleId,
    String componentId,
  ) => '${moduleComponents(organizationId, moduleId)}/$componentId';

  // ---------------------------------------------------------------------------
  // Components
  // ---------------------------------------------------------------------------

  static String components(String organizationId) =>
      '${workspace(organizationId)}/components';

  static String componentsAll(String organizationId) =>
      '${components(organizationId)}/all';

  static String componentById(String organizationId, String componentId) =>
      '${components(organizationId)}/$componentId';

  static String componentAllById(String organizationId, String componentId) =>
      '${componentsAll(organizationId)}/$componentId';

  static String componentActiveById(String organizationId, String componentId) =>
      '${componentById(organizationId, componentId)}/active';

  /// `/organizations/{organizationId}/workspace/components/{componentId}/modules`
  static String componentModules(String organizationId, String componentId) =>
      '${componentById(organizationId, componentId)}/modules';

  // ---------------------------------------------------------------------------
  // Tags
  // ---------------------------------------------------------------------------

  static String tags(String organizationId) =>
      '${workspace(organizationId)}/tags';

  static String tagsAll(String organizationId) => '${tags(organizationId)}/all';

  static String tagById(String organizationId, String tagId) =>
      '${tags(organizationId)}/$tagId';

  static String tagActiveById(String organizationId, String tagId) =>
      '${tagById(organizationId, tagId)}/active';

  // ---------------------------------------------------------------------------
  // Developers
  // ---------------------------------------------------------------------------

  static String developers(String organizationId) =>
      '${workspace(organizationId)}/developers';

  // ---------------------------------------------------------------------------
  // Discussions
  // ---------------------------------------------------------------------------

  static String discussions(String organizationId) =>
      '${workspace(organizationId)}/discussions';

  static String discussionById(String organizationId, String discussionId) =>
      '${discussions(organizationId)}/$discussionId';

  static String discussionStatusById(
    String organizationId,
    String discussionId,
  ) => '${discussionById(organizationId, discussionId)}/status';

  static String discussionReadById(
    String organizationId,
    String discussionId,
  ) => '${discussionById(organizationId, discussionId)}/read';

  static String discussionAssignmentsById(
    String organizationId,
    String discussionId,
  ) => '${discussionById(organizationId, discussionId)}/assignments';

  static String discussionAssignmentByIds(
    String organizationId,
    String discussionId,
    String developerUserId,
  ) =>
      '${discussionAssignmentsById(organizationId, discussionId)}/$developerUserId';

  // ---------------------------------------------------------------------------
  // Discussion context (modules / components / tags)
  // ---------------------------------------------------------------------------

  /// `discussions/{discussionId}/modules`
  static String discussionModules(String organizationId, String discussionId) =>
      '${discussionById(organizationId, discussionId)}/modules';

  /// `discussions/{discussionId}/modules/{moduleId}`
  static String discussionModuleByIds(
    String organizationId,
    String discussionId,
    String moduleId,
  ) => '${discussionModules(organizationId, discussionId)}/$moduleId';

  /// `discussions/{discussionId}/components`
  static String discussionComponents(
    String organizationId,
    String discussionId,
  ) => '${discussionById(organizationId, discussionId)}/components';

  /// `discussions/{discussionId}/components/{componentId}`
  static String discussionComponentByIds(
    String organizationId,
    String discussionId,
    String componentId,
  ) => '${discussionComponents(organizationId, discussionId)}/$componentId';

  /// `discussions/{discussionId}/tags`
  static String discussionTags(String organizationId, String discussionId) =>
      '${discussionById(organizationId, discussionId)}/tags';

  /// `discussions/{discussionId}/tags/{tagId}`
  static String discussionTagByIds(
    String organizationId,
    String discussionId,
    String tagId,
  ) => '${discussionTags(organizationId, discussionId)}/$tagId';

  // ---------------------------------------------------------------------------
  // Discussion messages
  // ---------------------------------------------------------------------------

  static String discussionMessagesByDiscussionId(
    String organizationId,
    String discussionId,
  ) => '${discussionById(organizationId, discussionId)}/messages';

  static String discussionMessageFilesByDiscussionId(
    String organizationId,
    String discussionId,
  ) =>
      '${discussionMessagesByDiscussionId(organizationId, discussionId)}/files';

  static String discussionMessageByIds(
    String organizationId,
    String discussionId,
    String messageId,
  ) =>
      '${discussionMessagesByDiscussionId(organizationId, discussionId)}/$messageId';
}
