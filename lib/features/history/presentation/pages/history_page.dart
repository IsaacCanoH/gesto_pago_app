import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/formatting/payment_date.dart';
import '../../../../core/ui/app_widgets.dart';
import '../../../purchases/data/models/purchase_result.dart';
import '../../../purchases/data/purchases_repository.dart';
import '../../data/history_repository.dart';
import '../../data/models/transaction.dart';
import '../view_models/history_view_model.dart';
import 'transaction_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    required this.repository,
    required this.token,
    required this.consultPurchase,
    required this.onSessionExpired,
  });

  final HistoryRepository repository;
  final String token;
  final ConsultPurchase consultPurchase;
  final VoidCallback onSessionExpired;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final model = HistoryViewModel(
    repository: widget.repository,
    token: widget.token,
    consultPurchase: widget.consultPurchase,
  )..load(0);

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  Widget _pagination() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton(
        tooltip: 'Página anterior',
        icon: const Icon(Icons.chevron_left),
        onPressed: model.canChangePage && model.page > 0
            ? () => model.load(model.page - 1)
            : null,
      ),
      Flexible(child: Text('Página ${model.page + 1} de ${model.totalPages}')),
      IconButton(
        tooltip: 'Página siguiente',
        icon: const Icon(Icons.chevron_right),
        onPressed: model.canChangePage && model.page + 1 < model.totalPages
            ? () => model.load(model.page + 1)
            : null,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, child) {
      final error = model.error;
      final expired = error?.statusCode == 401;
      return PageBody(
        children: [
          const PageHeading('Historial de pagos'),
          const SizedBox(height: 16),
          if (model.loading)
            const LinearProgressIndicator(semanticsLabel: 'Cargando historial'),
          if (error != null) ...[
            FieldError(error.message),
            TextButton(
              onPressed: expired ? widget.onSessionExpired : model.retry,
              child: Text(expired ? 'Volver a iniciar sesión' : 'Reintentar'),
            ),
          ],
          if (model.transactions.isEmpty && !model.loading && error == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Todavía no tienes pagos en tu historial.',
                style: TextStyle(color: muted),
              ),
            ),
          if (model.totalPages > 1) ...[
            _pagination(),
            const SizedBox(height: 8),
          ],
          if (model.transactions.isNotEmpty)
            Surface(
              child: Column(
                children: [
                  for (final (index, transaction)
                      in model.transactions.indexed) ...[
                    if (index > 0) const Divider(),
                    _HistoryEntry(
                      key: ValueKey(transaction.upc),
                      transaction: transaction,
                      consultPurchase: widget.consultPurchase,
                      consulting: model.isConsulting(transaction.upc),
                      error: model.consultError(transaction.upc),
                      onConsult: model.loading
                          ? null
                          : () => model.consult(transaction),
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    },
  );
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({
    super.key,
    required this.transaction,
    required this.consultPurchase,
    required this.consulting,
    required this.error,
    required this.onConsult,
  });

  final PurchaseTransaction transaction;
  final ConsultPurchase consultPurchase;
  final bool consulting;
  final String? error;
  final VoidCallback? onConsult;

  @override
  Widget build(BuildContext context) {
    final status = transaction.status;
    final color = switch (status) {
      PurchaseStatus.successful => success,
      PurchaseStatus.rejected => danger,
      PurchaseStatus.pending => action,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: switch (transaction.type) {
            1 => const ProductMark(fixed: true),
            2 => const ProductMark(fixed: false),
            _ => const SizedBox.square(
              dimension: 44,
              child: Icon(Icons.payments_outlined, color: action),
            ),
          },
          title: Text(
            transaction.product,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatPaymentDate(transaction.createdAt)),
              Text('UPC ${transaction.upc}'),
              Text(
                '${transaction.money} MXN',
                style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
              Semantics(
                liveRegion: true,
                child: Text(
                  transaction.statusLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TransactionDetailPage(
                transaction: transaction,
                consultPurchase: consultPurchase,
              ),
            ),
          ),
        ),
        if (status == PurchaseStatus.pending)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: consulting ? null : onConsult,
                  icon: consulting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(consulting ? 'Consultando…' : 'Consultar estado'),
                ),
                if (error case final message?) FieldError(message),
              ],
            ),
          ),
      ],
    );
  }
}
