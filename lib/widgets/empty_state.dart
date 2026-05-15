import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'animated_pressable.dart';
import 'glass_card.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.icon,
  });

  final String title;
  final String message;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cleanMessage = _cleanMessage(message);
    if (cleanMessage != message) {
      debugPrint('UI error details hidden from user: $message');
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 620),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - value)),
                child: child,
              ),
            );
          },
          child: GlassCard(
            radius: 30,
            padding: const EdgeInsets.all(22),
            borderColor: _isError(title, message)
                ? colorScheme.error.withValues(alpha: 0.24)
                : colorScheme.glassStroke,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.88, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          (_isError(title, message)
                                  ? colorScheme.error
                                  : colorScheme.primary)
                              .withValues(alpha: 0.24),
                          colorScheme.tertiary.withValues(alpha: 0.16),
                        ],
                      ),
                    ),
                    child: Icon(
                      icon ??
                          (_isError(title, message)
                              ? Icons.warning_amber_rounded
                              : Icons.auto_stories_rounded),
                      size: 36,
                      color: _isError(title, message)
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  cleanMessage,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.textSecondary,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 22),
                  AnimatedPressable(child: action!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isError(String title, String message) {
    final source = '$title $message'.toLowerCase();
    return source.contains('error') ||
        source.contains('lỗi') ||
        source.contains('không tải') ||
        source.contains('failed-precondition') ||
        source.contains('requires an index') ||
        source.contains('permission-denied') ||
        source.contains('network');
  }

  String _cleanMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('failed-precondition') ||
        lower.contains('requires an index') ||
        lower.contains('composite index') ||
        lower.contains('indexes.json')) {
      return 'Hệ thống đang chuẩn bị dữ liệu. Vui lòng thử lại sau vài phút.';
    }
    if (lower.contains('permission-denied')) {
      return 'Bạn chưa có quyền xem nội dung này.';
    }
    if (lower.contains('network') ||
        lower.contains('unavailable') ||
        lower.contains('mất mạng') ||
        lower.contains('khong co mang')) {
      return 'Không có kết nối mạng. Vui lòng thử lại.';
    }
    final withoutException = raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceAll(RegExp(r'https?:\/\/\S+'), '')
        .trim();
    if (withoutException.length > 180) {
      return '${withoutException.substring(0, 177)}...';
    }
    return withoutException;
  }
}

class EmptyState extends EmptyStateView {
  const EmptyState({
    super.key,
    required super.title,
    required super.message,
    super.action,
    super.icon,
  });
}
