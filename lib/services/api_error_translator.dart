import 'dart:async';
import 'dart:io';

class ApiErrorTranslator {
  const ApiErrorTranslator._();

  static String readable(Object error) {
    final raw = error.toString().trim();
    final normalized = raw.toLowerCase();

    if (error is TimeoutException || normalized.contains('timeout')) {
      return 'Kết nối đang chậm. Vui lòng thử lại.';
    }
    if (error is SocketException ||
        normalized.contains('socketexception') ||
        normalized.contains('network') ||
        normalized.contains('connection')) {
      return 'Không có kết nối mạng. Vui lòng thử lại.';
    }
    if (normalized.contains('token_expired') ||
        normalized.contains('unauthorized') ||
        normalized.contains('invalid token')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (normalized.contains('forbidden') ||
        normalized.contains('permission_denied') ||
        normalized.contains('permission-denied')) {
      return 'Bạn chưa có quyền thực hiện thao tác này.';
    }
    if (normalized.contains('invalid_credentials')) {
      return 'Email hoặc mật khẩu chưa đúng.';
    }
    if (normalized.contains('not_found')) {
      return 'Không tìm thấy dữ liệu bạn cần.';
    }
    if (normalized.contains('upload')) {
      return 'Không thể cập nhật dữ liệu lúc này. Vui lòng thử lại.';
    }
    if (normalized.contains('server_error') || normalized.contains('500')) {
      return 'Hệ thống đang bận. Vui lòng thử lại sau.';
    }

    if (raw.startsWith('Exception: ')) {
      final message = raw.substring(11).trim();
      if (message.isNotEmpty && message.length <= 180) {
        return message;
      }
    }

    if (raw.isEmpty || raw.length > 180) {
      return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }
    return raw;
  }
}
