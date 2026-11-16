import 'package:flutter/material.dart';

import '../../../../core/ui/app_widgets.dart';
import '../../../purchases/presentation/pages/purchase_page.dart';
import '../../data/models/product.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final form = GlobalKey<FormState>();
  final reference = TextEditingController();
  final amount = TextEditingController();
  ProductOffer? denomination;

  @override
  void dispose() {
    reference.dispose();
    amount.dispose();
    super.dispose();
  }

  String? amountError(String? value) {
    final raw = value?.trim().replaceAll(',', '.') ?? '';
    if (!RegExp(r'^\d{1,13}(\.\d{1,2})?$').hasMatch(raw) ||
        double.parse(raw) <= 0) {
      return 'Ingresa un importe mayor a cero con hasta dos decimales.';
    }
    return null;
  }

  void review() {
    if (!form.currentState!.validate()) return;
    final total =
        denomination?.price?.toDouble() ??
        double.parse(amount.text.trim().replaceAll(',', '.'));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PurchasePage(
          product: widget.product,
          reference: reference.text.trim(),
          amount: total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: PageBody(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ProductMark(fixed: product.fixed),
          ),
          const SizedBox(height: 14),
          PageHeading(
            product.service,
            subtitle: product.fixed
                ? 'Recarga de precio fijo'
                : product.description,
          ),
          const SizedBox(height: 26),
          Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (product.fixed) ...[
                  DropdownButtonFormField<ProductOffer>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Importe de recarga',
                    ),
                    items: product.offers
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              '${value.name} · \$${value.price!.toStringAsFixed(2)} MXN',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => denomination = value,
                    validator: (value) =>
                        value == null ? 'Selecciona un importe.' : null,
                    errorBuilder: (context, error) => FieldError(error),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: reference,
                  decoration: InputDecoration(
                    labelText: product.fixed
                        ? 'Teléfono o identificador'
                        : 'Referencia',
                  ),
                  errorBuilder: (context, error) => FieldError(error),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (product.fixed &&
                        (text.length < 10 || text.length > 20)) {
                      return 'Ingresa un teléfono o identificador de 10 a 20 caracteres.';
                    }
                    if (text.isEmpty || text.length > 100) {
                      return 'Ingresa una referencia válida.';
                    }
                    return null;
                  },
                ),
                if (!product.fixed) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Importe a pagar',
                      prefixText: '\$ ',
                      suffixText: 'MXN',
                    ),
                    validator: amountError,
                    errorBuilder: (context, error) => FieldError(error),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: review,
                  child: const Text('Revisar compra'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
