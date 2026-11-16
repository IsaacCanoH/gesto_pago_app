import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../core/formatting/payment_date.dart';
import '../../../../core/ui/app_widgets.dart';
import '../../data/models/purchase_draft.dart';
import '../../data/models/purchase_result.dart';
import '../../data/purchases_repository.dart';
import '../view_models/purchase_result_view_model.dart';

class PurchaseResultPage extends StatefulWidget {
  const PurchaseResultPage({
    super.key,
    required this.draft,
    required this.accountLabel,
    required this.result,
    required this.consultPurchase,
  });

  final PurchaseDraft draft;
  final String accountLabel;
  final PurchaseResult? result;
  final ConsultPurchase consultPurchase;

  @override
  State<PurchaseResultPage> createState() => _PurchaseResultPageState();
}

class _PurchaseResultPageState extends State<PurchaseResultPage> {
  late final model = PurchaseResultViewModel(
    consult: widget.consultPurchase,
    result: widget.result,
  );

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  Future<void> copyUpc(String upc) async {
    await Clipboard.setData(ClipboardData(text: upc));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('UPC copiado')));
    }
  }

  Widget buildReceipt(PurchaseResult? result) {
    final date = result?.resolvedAt ?? result?.createdAt;
    final authorization = result?.authorization;
    return Surface(
      child: Column(
        children: [
          ReceiptRow('Cuenta de cargo', widget.accountLabel),
          if (date != null) ...[
            const Divider(),
            ReceiptRow('Fecha', formatPaymentDate(date)),
          ],
          if (result != null) ...[
            const Divider(),
            ReceiptRow('UPC', result.upc),
          ],
          if (authorization != null &&
              result?.status == PurchaseStatus.successful) ...[
            const Divider(),
            ReceiptRow('Autorización', authorization),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, child) {
      final result = model.result;
      final status = result?.status;
      final (icon, color, description) = switch (status) {
        PurchaseStatus.successful => (
          Icons.check_circle_outline,
          success,
          null,
        ),
        PurchaseStatus.rejected => (
          Icons.cancel_outlined,
          danger,
          'El pago fue rechazado.',
        ),
        PurchaseStatus.pending => (
          Icons.schedule_outlined,
          const Color(0xFF805300),
          result?.requiresManualReview == true
              ? 'El pago requiere revisión. Conserva el UPC para el seguimiento.'
              : 'La confirmación sigue en proceso. Puedes consultar el estado con el UPC.',
        ),
        null => (
          Icons.wifi_off_outlined,
          danger,
          'No pudimos confirmar el resultado. Evita repetir el pago hasta verificar el cargo.',
        ),
      };
      return Scaffold(
        appBar: AppBar(title: const Text('Resultado de compra')),
        body: PageBody(
          children: [
            Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 48, color: color),
                  const SizedBox(height: 10),
                  PageHeading(
                    status?.label ?? 'Resultado sin confirmar',
                    subtitle: widget.draft.productName,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.draft.amountLabel,
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (description != null) ...[
              const SizedBox(height: 12),
              Text(description, style: const TextStyle(color: muted)),
            ],
            const SizedBox(height: 24),
            buildReceipt(result),
            if (model.error case final error?) FieldError(error),
            const SizedBox(height: 20),
            if (status == PurchaseStatus.pending) ...[
              FilledButton(
                onPressed: model.loading ? null : model.refresh,
                child: Text(
                  model.loading ? 'Consultando estado…' : 'Consultar estado',
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (result != null)
              TextButton.icon(
                onPressed: () => copyUpc(result.upc),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copiar UPC'),
              ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver al catálogo'),
            ),
          ],
        ),
      );
    },
  );
}
