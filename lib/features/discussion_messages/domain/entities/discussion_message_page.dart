import 'discussion_message.dart';

class DiscussionMessagePage {
  const DiscussionMessagePage({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<DiscussionMessage> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNext => page < totalPages;

  static const DiscussionMessagePage empty = DiscussionMessagePage(
    data: [],
    page: 1,
    limit: 50,
    total: 0,
    totalPages: 0,
  );

  DiscussionMessagePage copyWith({
    List<DiscussionMessage>? data,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
  }) {
    return DiscussionMessagePage(
      data: data ?? this.data,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
