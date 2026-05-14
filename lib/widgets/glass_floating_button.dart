import 'package:flutter/material.dart';

import 'animated_pressable.dart';

class GlassFloatingButton extends StatelessWidget {
  const GlassFloatingButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedPressable(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label == null ? 18 : 20,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              Color.lerp(colorScheme.primary, colorScheme.tertiary, 0.45)!,
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.24),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.onPrimary),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(
                label!,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
