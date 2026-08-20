import 'package:flutter/material.dart';

import '../../../catalog_admin/presentation/pages/catalog_admin_page.dart';

class TagsPage extends StatelessWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CatalogAdminPage(initialTab: CatalogAdminTab.tags);
  }
}
