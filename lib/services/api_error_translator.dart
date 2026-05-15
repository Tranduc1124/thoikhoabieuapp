import 'dart:async';
import 'dart:io';

import '../api/api_exception.dart';

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
      return 'Không có kết nối mạng.';
    }
    if (error is ApiException) {
      return _mapApiCode(error.code, fallbackMessage: error.message);
    }
    if (normalized.contains('token_expired') ||
        normalized.contains('unauthorized') ||
        normalized.contains('invalid token')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (normalized.contains('forbidden') ||
        normalized.contains('permission_denied') ||
        normalized.contains('permission-denied')) {
      return 'Ứng dụng chưa được xác thực.';
    }
    if (normalized.contains('invalid_credentials')) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (normalized.contains('email_taken')) {
      return 'Email này đã được sử dụng.';
    }
    if (normalized.contains('invalid_input')) {
      return 'Vui lòng kiểm tra lại thông tin.';
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

  static String _mapApiCode(String code, {String fallbackMessage = ''}) {
    return switch (code) {
      'invalid_credentials' => 'Email hoặc mật khẩu không đúng.',
      'email_taken' => 'Email này đã được sử dụng.',
      'invalid_input' => 'Vui lòng kiểm tra lại thông tin.',
      'token_expired' ||
      'invalid_token' => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      'forbidden' => 'Ứng dụng chưa được xác thực.',
      'network_error' => 'Không có kết nối mạng.',
      'server_error' => 'Hệ thống đang bận. Vui lòng thử lại sau.',
      'not_found' => 'Không tìm thấy dữ liệu bạn cần.',
      _ =>
        fallbackMessage.trim().isNotEmpty
            ? fallbackMessage.trim()
            : 'Đã xảy ra lỗi. Vui lòng thử lại.',
    };
  }
}
