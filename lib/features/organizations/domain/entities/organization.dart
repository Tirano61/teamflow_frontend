/// Organizacion tal como la devuelve `POST /organizations`.
///
/// Solo transporta la identidad de la organizacion recien creada. La
/// pertenencia y el rol del usuario siguen viniendo de `GET /me/context`.
class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;
}
