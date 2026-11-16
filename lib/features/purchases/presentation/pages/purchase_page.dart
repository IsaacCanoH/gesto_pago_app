import 'package:flutter/material.dart';

import '../../../../core/ui/app_widgets.dart';
import '../../../../core/ui/code_input.dart';
import '../../data/models/charge_account.dart';
import '../../data/models/purchase_draft.dart';
import '../../data/models/purchase_request.dart';
import '../../data/purchases_repository.dart';
import '../view_models/purchase_view_model.dart';
import '../widgets/payment_progress_button.dart';
import 'purchase_result_page.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({
    super.key,
    required this.draft,
    required this.submitPurchase,
    required this.loadAccounts,
    required this.consultPurchase,
  });

  final PurchaseDraft draft;
  final SubmitPurchase submitPurchase;
  final LoadChargeAccounts loadAccounts;
  final ConsultPurchase consultPurchase;

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final pin = TextEditingController();
  late final model = PurchaseViewModel(
    send: widget.submitPurchase,
    fetchAccounts: widget.loadAccounts,
  );
  bool pinInvalid = false;
  bool accountMissing = false;

  @override
  void initState() {
    super.initState();
    model.loadAccounts();
  }

  @override
  void dispose() {
    pin.dispose();
    model.dispose();
    super.dispose();
  }

  Future<void> confirm() async {
    if (!model.canSubmit) return;
    final account = model.selectedAccount;
    setState(() {
      accountMissing = account == null;
      pinInvalid = pin.text.length != 6;
    });
    if (account == null || pinInvalid) return;

    final request = PurchaseRequest(
      draft: widget.draft,
      accountId: account.id,
      pin: pin.text,
    );
    FocusScope.of(context).unfocus();
    pin.clear();
    await model.submit(request);
    if (!mounted) return;

    final result = model.result;
    if (result == null && model.failure?.uncertain != true) return;

    final confirmation = ModalRoute.of(context);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => PurchaseResultPage(
          draft: widget.draft,
          accountLabel: account.label,
          result: result,
          consultPurchase: widget.consultPurchase,
        ),
      ),
      (route) => route.isFirst && route != confirmation,
    );
  }

  Widget buildAccountField() {
    if (model.loadingAccounts) {
      return const LinearProgressIndicator(semanticsLabel: 'Cargando cuentas');
    }
    final error = model.accountsError;
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldError(error.message),
          TextButton(
            onPressed: model.loadAccounts,
            child: const Text('Reintentar'),
          ),
        ],
      );
    }
    if (model.accounts.isEmpty) {
      return const FieldError('No tienes cuentas activas para pagar.');
    }
    const decoration = InputDecoration(labelText: 'Cuenta de cargo');
    if (model.accounts.length == 1) {
      return InputDecorator(
        decoration: decoration,
        child: Text(model.accounts.single.label),
      );
    }
    return DropdownButtonFormField<ChargeAccount>(
      initialValue: model.selectedAccount,
      decoration: decoration,
      isExpanded: true,
      items: [
        for (final (index, account) in model.accounts.indexed)
          DropdownMenuItem(
            value: account,
            child: Text('Cuenta ${index + 1} •••• ${account.lastFour}'),
          ),
      ],
      onChanged: model.canSubmit ? model.selectAccount : null,
    );
  }

  Widget buildReceipt(PurchaseDraft draft) => Surface(
    child: Column(
      children: [
        if (draft.serviceName != draft.productName) ...[
          ReceiptRow('Servicio', draft.serviceName),
          const Divider(),
        ],
        ReceiptRow('Producto', draft.productName),
        const Divider(),
        ReceiptRow(
          draft.fixed ? 'Teléfono o identificador' : 'Referencia',
          draft.reference,
        ),
        const Divider(),
        ReceiptRow('Total', draft.amountLabel, strong: true),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, child) {
      final failure = model.failure;
      return PopScope(
        canPop: !model.processing,
        child: Scaffold(
          appBar: AppBar(title: const Text('Confirmar compra')),
          body: PageBody(
            children: [
              const PageHeading('Revisa tu compra'),
              const SizedBox(height: 24),
              buildReceipt(widget.draft),
              const SizedBox(height: 24),
              buildAccountField(),
              if (accountMissing && model.selectedAccount == null)
                const FieldError('Selecciona una cuenta de cargo.'),
              if (failure?.field == PurchaseField.account)
                FieldError(failure!.message),
              const SizedBox(height: 20),
              Text(
                'PIN de pago',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text('Ingresa tu PIN de seis dígitos.'),
              const SizedBox(height: 12),
              CodeInput(
                controller: pin,
                label: 'PIN de pago',
                secret: true,
                enabled: model.canSubmit,
              ),
              if (pinInvalid)
                const FieldError('Ingresa los seis dígitos del PIN.')
              else if (failure?.field == PurchaseField.pin)
                FieldError(failure!.message),
              if (failure != null && failure.field == null)
                FieldError(failure.message),
              const SizedBox(height: 24),
              PaymentProgressButton(
                processing: model.processing,
                onPressed: model.canSubmit ? confirm : null,
              ),
            ],
          ),
        ),
      );
    },
  );
}
