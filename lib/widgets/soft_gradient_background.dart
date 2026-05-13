import 'package:flutter/material.dart';

class SoftGradientBackground extends StatelessWidget {
  const SoftGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0E1320), Color(0xFF16182A), Color(0xFF101A23)]
              : const [Color(0xFFF8FAFF), Color(0xFFF1F6FF), Color(0xFFFFF7F2)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _Glow(color: colorScheme.primary, size: 210),
          ),
          Positioned(
            top: 190,
            left: -90,
            child: _Glow(color: colorScheme.tertiary, size: 220),
          ),
          Positioned(
            bottom: -90,
            right: 18,
            child: _Glow(color: colorScheme.secondary, size: 190),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}
