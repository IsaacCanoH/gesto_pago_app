import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../core/ui/app_widgets.dart';
import '../../../purchases/data/models/purchase_result.dart';
import '../../../purchases/data/purchases_repository.dart';
import '../../data/models/transaction.dart';

class TransactionDetailPage extends StatefulWidget {
  const TransactionDetailPage({
    super.key,
    required this.transaction,
    required this.consultPurchase,
  });

  final PurchaseTransaction transaction;
  final ConsultPurchase consultPurchase;

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  late Future<PurchaseResult> _detail = _loadDetail();

  Future<PurchaseResult> _loadDetail() =>
      widget.consultPurchase(widget.transaction.upc);

  Future<void> _copyUpc() async {
    await Clipboard.setData(ClipboardData(text: widget.transaction.upc));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('UPC copiado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final typography = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const BrandMark(),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: FutureBuilder<PurchaseResult>(
        future: _detail,
        builder: (context, snapshot) {
          final result = snapshot.data;
          final status = result?.status ?? transaction.status;
          final confirmedAt = status == PurchaseStatus.successful
              ? result?.resolvedAt
              : null;
          final authorization = result?.authorization;
          final accountLastFour = result?.accountLastFour;

          return PageBody(
            children: [
              Row(
                children: [
                  BackButton(onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Detalle de compra',
                      style: typography.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                transaction.product,
                style: typography.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${transaction.money} MXN',
                style: typography.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _StatusBadge(status: status),
              ),
              const SizedBox(height: 20),
              Surface(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'UPC',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              transaction.upc,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copiar UPC',
                            icon: const Icon(
                              Icons.copy_outlined,
                              color: action,
                              size: 21,
                            ),
                            onPressed: _copyUpc,
                          ),
                        ],
                      ),
                      const Divider(),
                      ReceiptRow(
                        confirmedAt == null
                            ? 'Fecha de compra'
                            : 'Fecha de confirmación',
                        _formatDate(confirmedAt ?? transaction.createdAt),
                      ),
                      const Divider(),
                      ReceiptRow(
                        'Cuenta de cargo',
                        accountLastFour == null
                            ? 'No disponible'
                            : '•••• $accountLastFour',
                      ),
                      if (status == PurchaseStatus.successful &&
                          authorization != null) ...[
                        const Divider(),
                        ReceiptRow('Autorización', authorization),
                      ],
                    ],
                  ),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(
                    semanticsLabel: 'Cargando detalle',
                  ),
                ),
              if (snapshot.hasError) ...[
                const FieldError('No pudimos actualizar el detalle del pago.'),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => setState(() => _detail = _loadDetail()),
                    child: const Text('Reintentar'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver al historial'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final date = value.toLocal();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PurchaseStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, foreground, background) = switch (status) {
      PurchaseStatus.successful => (
        'Exitoso',
        Icons.check_circle,
        success,
        const Color(0xFFE2F2E5),
      ),
      PurchaseStatus.pending => (
        'Pendiente',
        Icons.schedule,
        action,
        const Color(0xFFEEE6F7),
      ),
      PurchaseStatus.rejected => (
        'Fallido',
        Icons.cancel,
        danger,
        const Color(0xFFFCE8EC),
      ),
    };
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
