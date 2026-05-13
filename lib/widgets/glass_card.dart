import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.radius = 28,
    this.onTap,
    this.opacity,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;
  final double? opacity;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: colorScheme.glassSurface.withValues(alpha: opacity ?? 1),
      border: Border.all(color: borderColor ?? colorScheme.glassStroke),
      boxShadow: [
        BoxShadow(
          color: colorScheme.softShadow,
          blurRadius: isDark ? 28 : 34,
          offset: const Offset(0, 18),
        ),
      ],
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Ink(
                decoration: decoration,
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
