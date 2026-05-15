import 'package:flutter/material.dart';

import 'api_error_translator.dart';

enum AppFeedbackType { success, error, warning, info, loading }

class AppUserMessageException implements Exception {
  const AppUserMessageException(
    this.userMessage, {
    this.debugMessage,
    this.type = AppFeedbackType.error,
  });

  final String userMessage;
  final String? debugMessage;
  final AppFeedbackType type;

  @override
  String toString() => userMessage;
}

class AppFeedbackService {
  const AppFeedbackService._();

  static String messageFor(
    Object error, {
    String fallback = 'Đã xảy ra lỗi. Vui lòng thử lại.',
  }) {
    if (error is AppUserMessageException) {
      return error.userMessage;
    }
    final message = ApiErrorTranslator.readable(error).trim();
    return message.isEmpty ? fallback : message;
  }

  static AppFeedbackType typeFor(Object error) {
    if (error is AppUserMessageException) {
      return error.type;
    }
    return AppFeedbackType.error;
  }

  static void success(BuildContext context, String message) {
    show(context, message, type: AppFeedbackType.success);
  }

  static void error(
    BuildContext context,
    Object error, {
    String fallback = 'Đã xảy ra lỗi. Vui lòng thử lại.',
  }) {
    show(context, messageFor(error, fallback: fallback), type: typeFor(error));
  }

  static void warning(BuildContext context, String message) {
    show(context, message, type: AppFeedbackType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message, type: AppFeedbackType.info);
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> loading(
    BuildContext context,
    String message,
  ) {
    return show(context, message, type: AppFeedbackType.loading);
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context,
    String message, {
    AppFeedbackType type = AppFeedbackType.info,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final theme = Theme.of(context);
    final colors = _colorsFor(theme, type);
    return messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.background,
        duration: type == AppFeedbackType.loading
            ? const Duration(days: 1)
            : const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(_iconFor(type), color: colors.foreground, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.snackBarTheme.contentTextStyle?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (type == AppFeedbackType.loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.foreground),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static _FeedbackColors _colorsFor(ThemeData theme, AppFeedbackType type) {
    final scheme = theme.colorScheme;
    return switch (type) {
      AppFeedbackType.success => _FeedbackColors(
        background: const Color(0xFF103226),
        foreground: const Color(0xFFE7FFF5),
      ),
      AppFeedbackType.error => _FeedbackColors(
        background: const Color(0xFF3B1420),
        foreground: const Color(0xFFFFE8EE),
      ),
      AppFeedbackType.warning => _FeedbackColors(
        background: const Color(0xFF3B2B12),
        foreground: const Color(0xFFFFF3DA),
      ),
      AppFeedbackType.loading => _FeedbackColors(
        background: theme.brightness == Brightness.dark
            ? const Color(0xFF182235)
            : const Color(0xFFF8FBFF),
        foreground: scheme.onSurface,
      ),
      AppFeedbackType.info => _FeedbackColors(
        background: theme.brightness == Brightness.dark
            ? const Color(0xFF182235)
            : const Color(0xFFF8FBFF),
        foreground: scheme.onSurface,
      ),
    };
  }

  static IconData _iconFor(AppFeedbackType type) {
    return switch (type) {
      AppFeedbackType.success => Icons.check_circle_rounded,
      AppFeedbackType.error => Icons.error_rounded,
      AppFeedbackType.warning => Icons.warning_amber_rounded,
      AppFeedbackType.loading => Icons.sync_rounded,
      AppFeedbackType.info => Icons.info_rounded,
    };
  }
}

class _FeedbackColors {
  const _FeedbackColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
