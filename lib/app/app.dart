import 'dart:async';

import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/models/auth_session.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/history/data/history_repository.dart';
import '../features/purchases/data/purchases_repository.dart';
import 'shell.dart';
import 'theme.dart';

class GestoPagoApp extends StatefulWidget {
  const GestoPagoApp({super.key, this.authRepository, this.catalogRepository});
  final AuthRepository? authRepository;
  final CatalogRepository? catalogRepository;

  @override
  State<GestoPagoApp> createState() => _GestoPagoAppState();
}

class _GestoPagoAppState extends State<GestoPagoApp>
    with WidgetsBindingObserver {
  late final client = ApiClient(ApiConfig.baseUrl);
  late final catalog = widget.catalogRepository ?? CatalogRepository(client);
  late final repository = widget.authRepository ?? AuthRepository(client);
  late final history = HistoryRepository(client);
  late final purchases = PurchasesRepository(client);
  AuthSession? session;
  Timer? expiry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void onSignedIn(AuthSession value) {
    expiry?.cancel();
    expiry = Timer(value.expiresAt.difference(DateTime.now()), endSession);
    setState(() => session = value);
  }

  void endSession() {
    expiry?.cancel();
    setState(() => session = null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final current = session;
    if (state == AppLifecycleState.resumed &&
        current != null &&
        !current.expiresAt.isAfter(DateTime.now())) {
      endSession();
    }
  }

  @override
  void dispose() {
    expiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    key: ValueKey(session == null ? 'login' : 'session'),
    title: 'Gesto Pago',
    debugShowCheckedModeBanner: false,
    theme: gestoPagoTheme(),
    home: session != null
        ? AppShell(
            catalogRepository: catalog,
            historyRepository: history,
            purchasesRepository: purchases,
            token: session!.token,
            onExit: endSession,
          )
        : LoginPage(repository: repository, onSignedIn: onSignedIn),
  );
}
