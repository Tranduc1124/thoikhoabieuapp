import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
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
      scale: 0.94,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label == null ? AppSpacing.lg : AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              Color.lerp(colorScheme.primary, colorScheme.tertiary, 0.45)!,
            ],
          ),
          border: Border.all(color: colorScheme.glassStroke),
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
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
