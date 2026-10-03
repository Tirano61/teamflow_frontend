import '../../../../core/error/result.dart';
import '../repositories/organization_repository.dart';

class DeleteOrganization {
  const DeleteOrganization(this._repository);

  final OrganizationRepository _repository;

  /// Elimina definitivamente la organizacion activa.
  ///
  /// Requiere una autorizacion `DELETE_ORGANIZATION` ya verificada, que el
  /// backend busca por su cuenta. Quien llama debe recargar `/me/context`
  /// despues: la pertenencia nunca se corrige a mano.
  Future<Result<void>> call() {
    return _repository.deleteActiveOrganization();
  }
}
