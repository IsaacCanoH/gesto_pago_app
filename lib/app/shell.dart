import 'package:flutter/material.dart';

import '../core/ui/app_widgets.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.email, required this.onExit});
  final String? email;
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
    body: PageBody(children: [PageHeading('Sesión iniciada', subtitle: email)]),
  );
}
