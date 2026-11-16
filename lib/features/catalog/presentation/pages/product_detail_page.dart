import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/ui/app_widgets.dart';
import '../../../purchases/presentation/pages/purchase_page.dart';
import '../../data/models/product.dart';
import '../view_models/product_detail_view_model.dart';

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
  late final model = ProductDetailViewModel(widget.product);
  ProductOffer? denomination;
  bool reviewing = false;

  @override
  void dispose() {
    reference.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> review() async {
    if (reviewing || !form.currentState!.validate()) return;
    final draft = model.draft(
      denomination: denomination,
      reference: reference.text,
      amount: amount.text,
    );
    if (draft == null) return;

    FocusScope.of(context).unfocus();
    setState(() => reviewing = true);
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => PurchasePage(draft: draft)));
    if (mounted) setState(() => reviewing = false);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final legend = model.legendFor(denomination);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: PageBody(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ProductMark(fixed: product.fixed),
          ),
          const SizedBox(height: 14),
          PageHeading(product.service, subtitle: product.description),
          const SizedBox(height: 26),
          Form(
            key: form,
            autovalidateMode: AutovalidateMode.onUserInteractionIfError,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (product.fixed) ...[
                  DropdownButtonFormField<ProductOffer>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Importe de recarga',
                    ),
                    items: [
                      for (final offer in product.offers)
                        DropdownMenuItem(
                          value: offer,
                          child: Text(
                            '${offer.name} · \$${offer.price!.toStringAsFixed(2)} MXN',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => denomination = value),
                    validator: model.validateOffer,
                    errorBuilder: (context, error) => FieldError(error),
                  ),
                  const SizedBox(height: 16),
                ],
                if (legend != null) ...[
                  Surface(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: action,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              legend,
                              style: const TextStyle(color: muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: reference,
                  textInputAction: product.fixed
                      ? TextInputAction.done
                      : TextInputAction.next,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: product.fixed
                        ? 'Teléfono o identificador'
                        : 'Referencia',
                  ),
                  errorBuilder: (context, error) => FieldError(error),
                  validator: model.validateReference,
                  onFieldSubmitted: product.fixed ? (_) => review() : null,
                ),
                if (!product.fixed) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amount,
                    textInputAction: TextInputAction.done,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Importe a pagar',
                      prefixText: '\$ ',
                      suffixText: 'MXN',
                    ),
                    validator: model.validateAmount,
                    errorBuilder: (context, error) => FieldError(error),
                    onFieldSubmitted: (_) => review(),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: reviewing ? null : review,
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
