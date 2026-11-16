import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/ui/app_widgets.dart';
import '../../data/catalog_repository.dart';
import '../view_models/catalog_view_model.dart';
import 'product_detail_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.repository,
    required this.token,
    required this.onSessionExpired,
  });

  final CatalogRepository repository;
  final String token;
  final VoidCallback onSessionExpired;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  static const pageSize = 10;
  final search = TextEditingController();
  final scroll = ScrollController();
  late final model = CatalogViewModel(widget.repository, widget.token);
  int filter = 0;
  int page = 0;

  @override
  void initState() {
    super.initState();
    model.load();
  }

  @override
  void dispose() {
    model.dispose();
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  void selectPage(int value) {
    setState(() => page = value);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  Future<void> refresh() {
    if (page != 0) selectPage(0);
    return model.load();
  }

  Widget buildPagination(int currentPage, int pageCount) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Página anterior',
          onPressed: currentPage == 0
              ? null
              : () => selectPage(currentPage - 1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            'Página ${currentPage + 1} de $pageCount',
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          tooltip: 'Página siguiente',
          onPressed: currentPage + 1 >= pageCount
              ? null
              : () => selectPage(currentPage + 1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );

  Widget buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const PageHeading('Catálogo', subtitle: 'Recargas y pagos de servicios'),
      const SizedBox(height: 24),
      TextField(
        controller: search,
        onChanged: (_) => selectPage(0),
        decoration: const InputDecoration(
          labelText: 'Buscar servicio',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: [
          for (final (index, label) in const [
            'Todos',
            'Recargas',
            'Servicios',
          ].indexed)
            ChoiceChip(
              label: Text(label),
              selected: filter == index,
              onSelected: (_) => setState(() {
                filter = index;
                page = 0;
              }),
            ),
        ],
      ),
      const SizedBox(height: 16),
    ],
  );

  Widget buildStatus() {
    final error = model.error;
    if (model.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(semanticsLabel: 'Cargando catálogo'),
        ),
      );
    }
    if (error != null) {
      final expired = error.statusCode == 401;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldError(error.message),
          TextButton(
            onPressed: expired ? widget.onSessionExpired : model.load,
            child: Text(expired ? 'Volver a iniciar sesión' : 'Reintentar'),
          ),
        ],
      );
    }
    return Text(
      model.products.isEmpty
          ? 'No hay servicios disponibles en este momento.'
          : 'No encontramos servicios con esa búsqueda.',
      style: const TextStyle(color: muted),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, child) {
      final query = search.text.trim().toLowerCase();
      final visible = model.products
          .where(
            (product) =>
                (filter == 0 || product.type == filter) &&
                (product.service.toLowerCase().contains(query) ||
                    product.offers.any(
                      (offer) => offer.name.toLowerCase().contains(query),
                    )),
          )
          .toList();
      final showStatus =
          model.loading || model.error != null || visible.isEmpty;
      final pageCount = (visible.length + pageSize - 1) ~/ pageSize;
      final currentPage = page < pageCount ? page : 0;
      final pageProducts = visible
          .skip(currentPage * pageSize)
          .take(pageSize)
          .toList();
      final showPagination = pageCount > 1;

      return SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                controller: scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                itemCount: showStatus
                    ? 2
                    : pageProducts.length + (showPagination ? 2 : 1),
                itemBuilder: (context, index) {
                  if (index == 0) return buildHeader();
                  if (showStatus) return buildStatus();
                  if (index > pageProducts.length) {
                    return buildPagination(currentPage, pageCount);
                  }
                  final product = pageProducts[index - 1];
                  final radius = BorderRadius.vertical(
                    top: index == 1 ? const Radius.circular(14) : Radius.zero,
                    bottom: index == pageProducts.length
                        ? const Radius.circular(14)
                        : Radius.zero,
                  );
                  return Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: radius,
                      side: const BorderSide(color: line),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: ProductMark(fixed: product.fixed),
                      title: Text(
                        product.service,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        product.description == product.service
                            ? 'Pago de servicio'
                            : product.description,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProductDetailPage(product: product),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}
