import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/ui/app_widgets.dart';

class RegistrationLayout extends StatelessWidget {
  const RegistrationLayout({
    super.key,
    required this.child,
    required this.footer,
    this.onBack,
    this.canGoBack = true,
    this.scrollController,
  });

  final Widget child;
  final Widget footer;
  final VoidCallback? onBack;
  final bool canGoBack;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -86,
          right: -86,
          child: IgnorePointer(
            child: Container(
              width: 190,
              height: 190,
              decoration: const BoxDecoration(
                color: Color(0xFFEEE6F7),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 24, 12),
                    child: Row(
                      children: [
                        if (onBack != null) ...[
                          IconButton(
                            tooltip: 'Volver',
                            onPressed: canGoBack ? onBack : null,
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: ink,
                          ),
                          const SizedBox(width: 8),
                        ] else
                          const SizedBox(width: 8),
                        const Expanded(child: BrandMark()),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                      child: child,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    child: footer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class RegistrationProgress extends StatelessWidget {
  const RegistrationProgress({
    super.key,
    required this.index,
    required this.total,
  });

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Paso ${index + 1} de $total',
    value: '${((index + 1) / total * 100).round()}%',
    child: ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              total,
              (segment) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: segment == total - 1 ? 0 : 6),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: segment <= index ? brand : line,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Paso ${index + 1} de $total',
            style: const TextStyle(color: muted, fontSize: 15),
          ),
        ],
      ),
    ),
  );
}
