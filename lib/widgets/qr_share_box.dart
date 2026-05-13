import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'glass_card.dart';

class QrShareBox extends StatelessWidget {
  const QrShareBox({
    super.key,
    required this.data,
    this.size = 132,
    this.label,
  });

  final String data;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: QrImageView(
              data: data,
              size: size,
              backgroundColor: Colors.white,
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
            const SizedBox(height: 10),
            Text(
              label!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }
}
