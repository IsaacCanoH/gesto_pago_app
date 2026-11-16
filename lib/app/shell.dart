import 'package:flutter/material.dart';

import '../core/ui/app_widgets.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/catalog/presentation/pages/catalog_page.dart';
import '../features/catalog/presentation/pages/product_detail_page.dart';
import '../features/history/data/history_repository.dart';
import '../features/history/presentation/pages/history_page.dart';
import '../features/purchases/data/purchases_repository.dart';
import 'theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.catalogRepository,
    required this.historyRepository,
    required this.purchasesRepository,
    required this.token,
    required this.onExit,
  });

  final CatalogRepository catalogRepository;
  final HistoryRepository historyRepository;
  final PurchasesRepository purchasesRepository;
  final String token;
  final VoidCallback onExit;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  void _selectTab(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _tab == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _tab != 0) _selectTab(0);
    },
    child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const BrandMark(),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: widget.onExit,
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          CatalogPage(
            repository: widget.catalogRepository,
            token: widget.token,
            onSessionExpired: widget.onExit,
            onProductSelected: (product) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProductDetailPage(
                  product: product,
                  loadAccounts: () =>
                      widget.purchasesRepository.loadAccounts(widget.token),
                  consultPurchase: (upc) =>
                      widget.purchasesRepository.consult(widget.token, upc),
                  submitPurchase: (request) =>
                      widget.purchasesRepository.submit(widget.token, request),
                ),
              ),
            ),
          ),
          if (_tab == 1)
            HistoryPage(
              repository: widget.historyRepository,
              token: widget.token,
              consultPurchase: (upc) =>
                  widget.purchasesRepository.consult(widget.token, upc),
              onSessionExpired: widget.onExit,
            )
          else
            const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: line)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _selectTab,
          backgroundColor: canvas,
          surfaceTintColor: Colors.transparent,
          indicatorColor: action,
          height: 64,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined, color: muted),
              selectedIcon: Icon(
                Icons.storefront_outlined,
                color: Colors.white,
              ),
              label: 'Catálogo',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined, color: muted),
              selectedIcon: Icon(Icons.schedule_outlined, color: Colors.white),
              label: 'Historial',
            ),
          ],
        ),
      ),
    ),
  );
}
