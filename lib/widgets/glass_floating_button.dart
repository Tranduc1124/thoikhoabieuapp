import 'package:flutter/material.dart';

import 'animated_pressable.dart';
import 'glass_card.dart';

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
      child: GlassCard(
        radius: 24,
        padding: EdgeInsets.symmetric(
          horizontal: label == null ? 18 : 20,
          vertical: 16,
        ),
        borderColor: colorScheme.primary.withValues(alpha: 0.22),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.primary),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(
                label!,
                style: TextStyle(
                  color: colorScheme.primary,
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
