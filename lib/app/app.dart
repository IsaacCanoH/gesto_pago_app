import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/network/authenticated_api_client.dart';
import '../features/accounts/data/accounts_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/view_models/session_view_model.dart';
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
  late final repository = widget.authRepository ?? AuthRepository(client);
  late final sessions = SessionViewModel(repository);
  late final authenticated = AuthenticatedApiClient(
    client,
    sessions.tokenForRequest,
    sessions.reject,
  );
  late final catalog =
      widget.catalogRepository ?? CatalogRepository(authenticated);
  late final history = HistoryRepository(authenticated);
  late final accounts = AccountsRepository(authenticated);
  late final purchases = PurchasesRepository(authenticated);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) sessions.checkExpiry();
  }

  @override
  void dispose() {
    sessions.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: sessions,
    builder: (context, child) => MaterialApp(
      key: ValueKey(sessions.current == null ? 'login' : 'session'),
      title: 'Gesto Pago',
      debugShowCheckedModeBanner: false,
      theme: gestoPagoTheme(),
      home: sessions.current != null
          ? AppShell(
              catalogRepository: catalog,
              accountsRepository: accounts,
              historyRepository: history,
              purchasesRepository: purchases,
              token: sessions.initialToken!,
              onExit: () => sessions.clear(),
              onLogout: sessions.signOut,
              closingSession: sessions.closing,
              logoutError: sessions.logoutError,
            )
          : LoginPage(
              repository: repository,
              onSignedIn: sessions.start,
              sessionMessage: sessions.notice,
            ),
    ),
  );
}
