class ApiEndpoints {
  const ApiEndpoints._();

  static const String authLogin = '/auth/login';

    static const String _workspace = '/develop-workflow';

    static const String applications = '$_workspace/applications';
    static const String indicators = '$_workspace/indicators';
    static const String tags = '$_workspace/tags';
    static const String discussions = '$_workspace/discussions';
    static const String developers = '$_workspace/developers';
    static const String devices = '$_workspace/devices';

  static String applicationById(String id) => '$applications/$id';

  static String applicationsAll() => '$applications/all';

  static String applicationActiveById(String id) => '${applicationById(id)}/active';

  static String applicationIndicatorsById(String applicationId) =>
      '${applicationById(applicationId)}/indicators';

  static String applicationIndicatorByIds(String applicationId, String indicatorId) =>
      '${applicationIndicatorsById(applicationId)}/$indicatorId';

  static String indicatorById(String id) => '$indicators/$id';

  static String indicatorsAll() => '$indicators/all';

  static String indicatorActiveById(String id) => '${indicatorById(id)}/active';

  static String indicatorApplicationsById(String indicatorId) =>
      '${indicatorById(indicatorId)}/applications';

  static String tagsAll() => '$tags/all';

  static String tagById(String id) => '$tags/$id';

  static String tagActiveById(String id) => '${tagById(id)}/active';

  static String discussionById(String id) => '$discussions/$id';

  static String discussionStatusById(String id) =>
      '${discussionById(id)}/status';

  static String discussionReadById(String id) => '${discussionById(id)}/read';

  static String discussionAssignmentsById(String id) =>
      '${discussionById(id)}/assignments';

  static String discussionAssignmentByIds(String id, String developerUserId) =>
      '${discussionAssignmentsById(id)}/$developerUserId';

  static String discussionMessagesByDiscussionId(String discussionId) =>
      '${discussionById(discussionId)}/messages';

  static String discussionMessageFilesByDiscussionId(String discussionId) =>
      '${discussionMessagesByDiscussionId(discussionId)}/files';

  static String discussionMessageByIds(String discussionId, String messageId) =>
      '${discussionMessagesByDiscussionId(discussionId)}/$messageId';
}


