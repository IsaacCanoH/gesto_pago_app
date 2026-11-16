import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/ui/app_widgets.dart';
import '../../data/models/product.dart';
import 'product_detail_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.products});
  final List<Product> products;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final search = TextEditingController();
  int filter = 0;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final visible = widget.products
        .where(
          (product) =>
              (filter == 0 || product.type == filter) &&
              product.service.toLowerCase().contains(query),
        )
        .toList();
    return PageBody(
      children: [
        const PageHeading(
          'Catálogo',
          subtitle: 'Recargas y pagos de servicios',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Buscar servicio',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in const [
              'Todos',
              'Recargas',
              'Servicios',
            ].asMap().entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: filter == entry.key,
                onSelected: (_) => setState(() => filter = entry.key),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          const Text(
            'No encontramos servicios con esa búsqueda.',
            style: TextStyle(color: muted),
          )
        else
          Surface(
            child: Column(
              children: [
                for (final (index, product) in visible.indexed) ...[
                  if (index > 0) const Divider(),
                  ListTile(
                    leading: ProductMark(fixed: product.fixed),
                    title: Text(
                      product.service,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      product.fixed
                          ? 'Recarga de precio fijo'
                          : 'Pago de importe variable',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProductDetailPage(product: product),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
