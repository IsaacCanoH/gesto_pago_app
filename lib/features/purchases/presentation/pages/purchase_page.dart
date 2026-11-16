import 'package:flutter/material.dart';

import '../../../../core/ui/app_widgets.dart';
import '../../../../core/ui/code_input.dart';
import '../../data/models/purchase_draft.dart';
import '../widgets/payment_progress_button.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({
    super.key,
    required this.draft,
    this.account,
    this.processing = false,
  });
  final PurchaseDraft draft;
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
                if (widget.draft.serviceName != widget.draft.productName) ...[
                  ReceiptRow('Servicio', widget.draft.serviceName),
                  const Divider(),
                ],
                ReceiptRow('Producto', widget.draft.productName),
                const Divider(),
                ReceiptRow(
                  widget.draft.fixed
                      ? 'Teléfono o identificador'
                      : 'Referencia',
                  widget.draft.reference,
                ),
                const Divider(),
                if (widget.account != null) ...[
                  ReceiptRow('Cuenta de cargo', widget.account!),
                  const Divider(),
                ],
                ReceiptRow('Total', widget.draft.amountLabel, strong: true),
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
