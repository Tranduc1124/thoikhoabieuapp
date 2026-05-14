import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

class QrShareBox extends StatelessWidget {
  const QrShareBox({
    super.key,
    required this.data,
    this.size = 152,
    this.label,
    this.subtitle,
  });

  final String data;
  final double size;
  final String? label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      radius: 30,
      padding: const EdgeInsets.all(18),
      borderColor: colorScheme.primary.withValues(alpha: 0.18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.18),
                  AppColors.lavender.withValues(alpha: 0.14),
                  AppColors.sky.withValues(alpha: 0.12),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFEFF),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: data,
                    size: size,
                    backgroundColor: const Color(0xFFFDFEFF),
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: Color(0xFF111827),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                if (label != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    label!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.textPrimary,
                    ),
                  ),
                ],
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
