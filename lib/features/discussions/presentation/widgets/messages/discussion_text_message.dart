import 'package:flutter/material.dart';

class DiscussionTextMessage extends StatelessWidget {
  const DiscussionTextMessage({required this.content, super.key});

  final String content;

  @override
  Widget build(BuildContext context) {
    final trimmed = content.trim();
    return Text(
      trimmed.isEmpty ? '(sin contenido)' : trimmed,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
    );
  }
}
