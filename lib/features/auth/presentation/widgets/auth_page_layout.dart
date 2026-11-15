import 'package:flutter/material.dart';

class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  static const _primaryPurple = Color(0xFF8764C1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FC),
      body: Stack(
        children: [
          const _DecorativeBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BrandMark(),
                      const SizedBox(height: 40),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFF3F2A67),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF756B82),
                        ),
                      ),
                      const SizedBox(height: 32),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: AuthPageLayout._primaryPurple,
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [
            BoxShadow(
              color: Color(0x448764C1),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
      ),
    );
  }
}

class _DecorativeBackground extends StatelessWidget {
  const _DecorativeBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          _circle(top: -150, right: -90, size: 310, color: AuthPageLayout._primaryPurple),
          _circle(top: -82, right: 105, size: 145, color: const Color(0xFFA58AD5)),
          _circle(bottom: -85, left: -75, size: 205, color: const Color(0xFF7A55B7)),
          _circle(bottom: 82, left: 76, size: 42, color: const Color(0xFFC7B7E0)),
        ],
      ),
    );
  }

  Widget _circle({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
