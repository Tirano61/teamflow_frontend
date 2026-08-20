import '../../domain/entities/discussion.dart';

class DiscussionDetailRouteArgs {
  const DiscussionDetailRouteArgs({required this.discussionId});

  final String discussionId;
}

class DiscussionEditorRouteArgs {
  const DiscussionEditorRouteArgs({this.discussion, this.discussionId});

  final Discussion? discussion;
  final String? discussionId;
}
