import 'package:flutter/material.dart';

import '../../app/theme.dart';

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(subtitle!, style: const TextStyle(color: muted, fontSize: 16)),
      ],
    ],
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: brand,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(
          Icons.account_balance_wallet_outlined,
          color: Colors.white,
        ),
      ),
      const SizedBox(width: 12),
      const Flexible(
        child: Text(
          'Gesto Pago',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: danger),
          const SizedBox(width: 6),
          Expanded(
            child: Text(message, style: const TextStyle(color: danger)),
          ),
        ],
      ),
    ),
  );
}

class Surface extends StatelessWidget {
  const Surface({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: line),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

class ReceiptRow extends StatelessWidget {
  const ReceiptRow(this.label, this.value, {super.key, this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong ? ink : muted,
              fontWeight: strong ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: strong ? FontWeight.bold : FontWeight.w500,
              fontSize: strong ? 17 : 14,
            ),
          ),
        ),
      ],
    ),
  );
}

class ProductMark extends StatelessWidget {
  const ProductMark({super.key, required this.fixed});
  final bool fixed;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: const Color(0xFFEEE6F7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      fixed ? Icons.smartphone_outlined : Icons.receipt_long_outlined,
      color: action,
    ),
  );
}
