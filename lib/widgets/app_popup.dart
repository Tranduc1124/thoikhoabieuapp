import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import 'motion_widgets.dart';

enum AppPopupType { info, success, error }

Future<void> showAppPopup(
  BuildContext context, {
  required String title,
  required String message,
  AppPopupType type = AppPopupType.info,
  String? primaryLabel,
  VoidCallback? onPrimary,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'popup',
    barrierColor: Colors.black.withValues(alpha: 0.42),
    transitionDuration: AppMotion.medium,
    pageBuilder: (context, _, _) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondary, child) {
      return MorphTransitionWidget(
        animation: animation,
        beginOffset: const Offset(0, 0.03),
        beginScale: 0.94,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _PopupCard(
              title: title,
              message: message,
              type: type,
              primaryLabel: primaryLabel,
              onPrimary: onPrimary,
            ),
          ),
        ),
      );
    },
  );
}

class _PopupCard extends StatelessWidget {
  const _PopupCard({
    required this.title,
    required this.message,
    required this.type,
    this.primaryLabel,
    this.onPrimary,
  });

  final String title;
  final String message;
  final AppPopupType type;
  final String? primaryLabel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = switch (type) {
      AppPopupType.info => colorScheme.primary,
      AppPopupType.success => AppColors.success,
      AppPopupType.error => colorScheme.error,
    };
    final iconHighlight = context.isDark
        ? Color.lerp(accent, Colors.white, 0.16)!
        : Color.lerp(accent, Colors.white, 0.30)!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: context.surfaceColor.withValues(
                alpha: context.isDark ? 0.96 : 0.98,
              ),
              border: Border.all(color: context.borderColor),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [accent, iconHighlight],
                        ),
                      ),
                      child: Icon(switch (type) {
                        AppPopupType.info => Icons.info_rounded,
                        AppPopupType.success => Icons.check_rounded,
                        AppPopupType.error => Icons.close_rounded,
                      }, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    AnimatedButton(
                      onTap: () => Navigator.of(context).pop(),
                      scale: 0.92,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Đóng'),
                    ),
                    if (primaryLabel != null) ...[
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onPrimary?.call();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(primaryLabel!),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
