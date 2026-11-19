import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/ui/app_widgets.dart';
import '../../data/accounts_repository.dart';
import '../../data/models/managed_account.dart';
import '../view_models/accounts_view_model.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({
    super.key,
    required this.repository,
    required this.token,
    required this.onSessionExpired,
  });

  final AccountsRepository repository;
  final String token;
  final VoidCallback onSessionExpired;

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  late final model = AccountsViewModel(widget.repository, widget.token)..load();
  bool _confirming = false;

  Future<void> _confirmDeactivation(ManagedAccount account) async {
    if (_confirming || model.busy || model.sessionExpired) return;
    _confirming = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar cuenta'),
        content: Text(
          '¿Quieres desactivar ${account.label.toLowerCase()}? '
          'Dejará de estar disponible para realizar pagos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    _confirming = false;
    if (confirmed == true && mounted) await model.deactivate(account);
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final error = model.error;
      return PageBody(
        children: [
          Row(
            children: [
              const Expanded(child: PageHeading('Mis cuentas')),
              IconButton(
                tooltip: 'Actualizar cuentas',
                onPressed: model.busy || model.sessionExpired
                    ? null
                    : model.load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (model.loading)
            const LinearProgressIndicator(semanticsLabel: 'Cargando cuentas'),
          if (error != null) ...[
            FieldError(error.message),
            if (!model.sessionExpired)
              TextButton(
                onPressed: model.load,
                child: const Text('Reintentar'),
              ),
          ],
          if (model.sessionExpired)
            TextButton(
              onPressed: widget.onSessionExpired,
              child: const Text('Volver a iniciar sesión'),
            ),
          if (!model.loading && error == null && model.accounts.isEmpty)
            const Text(
              'Todavía no tienes cuentas de cargo.',
              style: TextStyle(color: muted),
            ),
          for (final account in model.accounts) ...[
            _AccountCard(
              key: ValueKey(account.id),
              account: account,
              busy: model.deactivatingId == account.id,
              error: model.failedAccountId == account.id
                  ? model.deactivationError?.message
                  : null,
              onDeactivate:
                  model.busy || model.sessionExpired || !account.canDeactivate
                  ? null
                  : () => _confirmDeactivation(account),
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
    },
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    super.key,
    required this.account,
    required this.busy,
    required this.error,
    required this.onDeactivate,
  });

  final ManagedAccount account;
  final bool busy;
  final String? error;
  final VoidCallback? onDeactivate;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).textTheme;
    final (label, color, icon) = switch (account.status) {
      'ACTIVA' => ('Activa', success, Icons.check_circle_outline),
      'INACTIVA' => ('Inactiva', muted, Icons.remove_circle_outline),
      _ => ('Estado no disponible', muted, Icons.info_outline),
    };
    return Surface(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: action,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    account.label,
                    style: typography.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            const Text('Saldo total', style: TextStyle(color: muted)),
            const SizedBox(height: 4),
            Text(
              account.money,
              style: typography.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  Icon(icon, size: 17, color: color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (account.isActive) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onDeactivate,
                style: OutlinedButton.styleFrom(foregroundColor: danger),
                icon: busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.block_outlined, size: 18),
                label: Text(busy ? 'Desactivando…' : 'Desactivar cuenta'),
              ),
              if (account.balance != 0)
                const FieldError(
                  'La cuenta debe tener saldo cero para desactivarla.',
                ),
            ],
            if (error case final message?) FieldError(message),
          ],
        ),
      ),
    );
  }
}
