import 'package:flutter/material.dart';

import '../../../catalog_admin/presentation/pages/catalog_admin_page.dart';

class WorkModulesPage extends StatelessWidget {
  const WorkModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CatalogAdminPage(initialTab: CatalogAdminTab.workModules);
  }
}



