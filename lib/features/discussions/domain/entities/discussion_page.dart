import 'discussion.dart';

class DiscussionPage {
  const DiscussionPage({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<Discussion> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNext => page < totalPages;

  static const DiscussionPage empty = DiscussionPage(
    data: [],
    page: 1,
    limit: 20,
    total: 0,
    totalPages: 0,
  );

  DiscussionPage copyWith({
    List<Discussion>? data,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
  }) {
    return DiscussionPage(
      data: data ?? this.data,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
