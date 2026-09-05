import '../../domain/entities/organization.dart';

enum OrganizationStatus { initial, creating, success, error }

class OrganizationState {
  const OrganizationState({
    this.status = OrganizationStatus.initial,
    this.createdOrganization,
    this.errorMessage = '',
  });

  final OrganizationStatus status;

  /// Ultima organizacion creada. La pertenencia real la confirma el refresh
  /// posterior de `/me/context`.
  final Organization? createdOrganization;
  final String errorMessage;

  /// Hay una creacion en curso: bloquea el doble submit.
  bool get isCreating => status == OrganizationStatus.creating;

  OrganizationState copyWith({
    OrganizationStatus? status,
    Organization? createdOrganization,
    bool clearCreatedOrganization = false,
    String? errorMessage,
  }) {
    return OrganizationState(
      status: status ?? this.status,
      createdOrganization: clearCreatedOrganization
          ? null
          : createdOrganization ?? this.createdOrganization,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
