import 'package:flutter/material.dart';

import '../../../../core/ui/app_widgets.dart';
import '../../../../core/ui/code_input.dart';
import '../../../catalog/data/models/product.dart';
import '../widgets/payment_progress_button.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({
    super.key,
    required this.product,
    required this.reference,
    required this.amount,
    this.account,
    this.processing = false,
  });
  final Product product;
  final String reference;
  final double amount;
  final String? account;
  final bool processing;

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final pin = TextEditingController();

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.processing,
    child: Scaffold(
      appBar: AppBar(title: const Text('Confirmar compra')),
      body: PageBody(
        children: [
          const PageHeading('Revisa tu compra'),
          const SizedBox(height: 24),
          Surface(
            child: Column(
              children: [
                ReceiptRow('Producto', widget.product.service),
                const Divider(),
                ReceiptRow(
                  widget.product.fixed ? 'Teléfono' : 'Referencia',
                  widget.reference,
                ),
                const Divider(),
                if (widget.account != null) ...[
                  ReceiptRow('Cuenta de cargo', widget.account!),
                  const Divider(),
                ],
                ReceiptRow(
                  'Total',
                  '\$${widget.amount.toStringAsFixed(2)} MXN',
                  strong: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('PIN de pago', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Ingresa tu PIN de seis dígitos.'),
          const SizedBox(height: 12),
          CodeInput(
            controller: pin,
            label: 'PIN de pago',
            secret: true,
            enabled: !widget.processing,
          ),
          const SizedBox(height: 24),
          PaymentProgressButton(processing: widget.processing, onPressed: null),
        ],
      ),
    ),
  );
}
