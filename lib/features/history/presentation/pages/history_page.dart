import 'package:flutter/material.dart';

import '../../../../core/ui/app_widgets.dart';
import '../../data/models/transaction.dart';
import 'transaction_detail_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.transactions});
  final List<PurchaseTransaction> transactions;

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const PageHeading('Historial', subtitle: 'Compras exitosas'),
      const SizedBox(height: 24),
      Surface(
        child: Column(
          children: [
            for (final (index, item) in transactions.indexed) ...[
              if (index > 0) const Divider(),
              ListTile(
                leading: ProductMark(fixed: item.fixed),
                title: Text(
                  item.product,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(item.date),
                trailing: Text(
                  item.money,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TransactionDetailPage(transaction: item),
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
