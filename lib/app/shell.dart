import 'package:flutter/material.dart';

import '../core/ui/app_widgets.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/catalog/presentation/pages/catalog_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.catalogRepository,
    required this.token,
    required this.onExit,
  });

  final CatalogRepository catalogRepository;
  final String token;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const BrandMark(),
      actions: [
        IconButton(
          tooltip: 'Cerrar sesión',
          icon: const Icon(Icons.logout),
          onPressed: onExit,
        ),
      ],
    ),
    body: CatalogPage(
      repository: catalogRepository,
      token: token,
      onSessionExpired: onExit,
    ),
  );
}
