sealed class OrganizationEvent {
  const OrganizationEvent();
}

/// El usuario confirmo el formulario de creacion de organizacion.
class CreateOrganizationRequested extends OrganizationEvent {
  const CreateOrganizationRequested(this.name);

  final String name;
}
