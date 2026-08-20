import '../../domain/entities/tag.dart';

sealed class TagEvent {
  const TagEvent();
}

class LoadTagsEvent extends TagEvent {
  const LoadTagsEvent({this.includeInactive = false});

  final bool includeInactive;
}

class CreateTagEvent extends TagEvent {
  const CreateTagEvent(this.tag);

  final Tag tag;
}

class UpdateTagEvent extends TagEvent {
  const UpdateTagEvent(this.tag);

  final Tag tag;
}

class SetTagActiveEvent extends TagEvent {
  const SetTagActiveEvent({required this.id, required this.active});

  final String id;
  final bool active;
}
