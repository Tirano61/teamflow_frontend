import '../../domain/entities/membership.dart';

enum MembershipStatus { initial, loading, success, error }

class MembershipState {
  const MembershipState({
    this.status = MembershipStatus.initial,
    this.members = const [],
    this.errorMessage = '',
  });

  final MembershipStatus status;
  final List<Membership> members;
  final String errorMessage;

  MembershipState copyWith({
    MembershipStatus? status,
    List<Membership>? members,
    String? errorMessage,
  }) {
    return MembershipState(
      status: status ?? this.status,
      members: members ?? this.members,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
