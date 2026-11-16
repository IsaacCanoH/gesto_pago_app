import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/formatting/payment_date.dart';
import '../../../../core/ui/app_widgets.dart';
import '../../data/models/transaction.dart';

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({super.key, required this.transaction});
  final PurchaseTransaction transaction;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle de compra')),
    body: PageBody(
      children: [
        PageHeading(transaction.product),
        const SizedBox(height: 8),
        Text(
          '${transaction.money} MXN',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          transaction.statusLabel,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        Surface(
          child: Column(
            children: [
              ReceiptRow('UPC', transaction.upc),
              const Divider(),
              ReceiptRow('Fecha', formatPaymentDate(transaction.createdAt)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copiar UPC'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: transaction.upc));
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('UPC copiado')));
            }
          },
        ),
      ],
    ),
  );
}
