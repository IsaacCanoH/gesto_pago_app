import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/ui/app_widgets.dart';
import '../../../history/data/models/transaction.dart';
import '../../../history/presentation/pages/transaction_detail_page.dart';

enum PaymentStatus {
  approved('Pago exitoso', Icons.check_circle_outline, success),
  rejected('Pago rechazado', Icons.cancel_outlined, danger),
  pending('Pago pendiente', Icons.schedule_outlined, Color(0xFF805300)),
  connection('Error de comunicación', Icons.wifi_off_outlined, danger);

  const PaymentStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class PurchaseResultPage extends StatelessWidget {
  const PurchaseResultPage({
    super.key,
    required this.transaction,
    required this.status,
  });
  final PurchaseTransaction transaction;
  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final item = transaction;
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado de compra')),
      body: PageBody(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(status.icon, size: 48, color: status.color),
          ),
          const SizedBox(height: 10),
          PageHeading(status.label, subtitle: item.product),
          const SizedBox(height: 8),
          Text(
            '${item.money} MXN',
            style: Theme.of(context).textTheme.headlineLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          if (status == PaymentStatus.approved) ...[
            Surface(
              child: Column(
                children: [
                  ReceiptRow('Fecha', item.date),
                  const Divider(),
                  ReceiptRow('UPC', item.upc),
                  const Divider(),
                  ReceiptRow('Autorización', item.authorization),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TransactionDetailPage(transaction: item),
                ),
              ),
              child: const Text('Ver detalle de compra'),
            ),
          ] else
            Text(switch (status) {
              PaymentStatus.pending =>
                'El proveedor aún está confirmando la operación.',
              PaymentStatus.rejected => 'El proveedor rechazó la operación.',
              _ => 'No pudimos confirmar el resultado. Evita repetir el pago.',
            }),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Volver al catálogo'),
          ),
        ],
      ),
    );
  }
}
