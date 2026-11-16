import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class PaymentProgressButton extends StatelessWidget {
  const PaymentProgressButton({
    super.key,
    required this.processing,
    required this.onPressed,
  });
  final bool processing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (!processing) {
      return FilledButton(
        onPressed: onPressed,
        child: const Text('Confirmar pago'),
      );
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      liveRegion: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 52,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: action),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 0.85),
                duration: Duration(milliseconds: reduceMotion ? 100 : 1100),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: reduceMotion ? 0.85 : value,
                  child: child,
                ),
                child: const ColoredBox(color: ink),
              ),
              Center(
                child: Text(
                  'Procesando pago…',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 16,
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
