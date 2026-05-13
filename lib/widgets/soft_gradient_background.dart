import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SoftGradientBackground extends StatelessWidget {
  const SoftGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.isDark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colorScheme.appBackgroundGradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: isDark ? -90 : -80,
            right: -70,
            child: _Glow(
              color: isDark ? colorScheme.primary : colorScheme.primary,
              size: 230,
              opacity: isDark ? 0.18 : 0.13,
            ),
          ),
          Positioned(
            top: 190,
            left: -90,
            child: _Glow(
              color: colorScheme.tertiary,
              size: 230,
              opacity: isDark ? 0.13 : 0.11,
            ),
          ),
          Positioned(
            bottom: -90,
            right: 18,
            child: _Glow(
              color: colorScheme.secondary,
              size: 210,
              opacity: isDark ? 0.12 : 0.10,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size, required this.opacity});

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.35),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
