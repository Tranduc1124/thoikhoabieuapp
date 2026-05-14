import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseErrorTranslator {
  const FirebaseErrorTranslator._();

  static String auth(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Email không hợp lệ.',
        'user-not-found' => 'Không tìm thấy tài khoản với email này.',
        'wrong-password' => 'Mật khẩu không đúng.',
        'invalid-credential' => 'Email hoặc mật khẩu không đúng.',
        'email-already-in-use' => 'Email này đã được đăng ký.',
        'weak-password' => 'Mật khẩu quá yếu. Hãy dùng ít nhất 6 ký tự.',
        'network-request-failed' =>
          'Không có kết nối mạng hoặc Firebase đang gián đoạn.',
        'internal-error' =>
          'Firebase đang gặp lỗi nội bộ. Vui lòng thử lại sau.',
        'operation-not-allowed' =>
          'Hãy bật Email/Password trong Firebase Authentication.',
        'account-exists-with-different-credential' =>
          'Email này đã đăng nhập bằng phương thức khác.',
        _ => error.message ?? 'Lỗi đăng nhập Firebase: ${error.code}.',
      };
    }
    return readable(error);
  }

  static String firestore(Object error) {
    if (error is FirebaseException) {
      return switch (error.code) {
        'failed-precondition' =>
          'Firebase đang tạo chỉ mục. Vui lòng thử lại sau vài phút.',
        'permission-denied' =>
          'Bạn chưa có quyền đọc dữ liệu. Kiểm tra Firestore Rules.',
        'unavailable' =>
          'Firestore đang không khả dụng hoặc mất mạng. Vui lòng thử lại.',
        'network-request-failed' => 'Không có kết nối mạng. Vui lòng thử lại.',
        'not-found' => 'Không tìm thấy dữ liệu cần truy cập.',
        'deadline-exceeded' => 'Yêu cầu quá lâu. Vui lòng thử lại.',
        _ => error.message ?? 'Lỗi Firestore: ${error.code}.',
      };
    }
    return readable(error);
  }

  static String readable(Object error) {
    final raw = error.toString().trim();
    final normalized = raw.toLowerCase();
    debugPrint('Readable error: $raw');
    if (normalized.contains('failed-precondition') ||
        normalized.contains('requires an index')) {
      return 'Firebase đang tạo chỉ mục. Vui lòng thử lại sau vài phút.';
    }
    if (normalized.contains('permission-denied')) {
      return 'Bạn chưa có quyền đọc dữ liệu. Kiểm tra Firestore Rules.';
    }
    if (normalized.contains('network') ||
        normalized.contains('socketexception') ||
        normalized.contains('unavailable')) {
      return 'Không có kết nối mạng. Vui lòng thử lại.';
    }
    if (normalized.contains('timeout')) {
      return 'Tác vụ mất quá nhiều thời gian. Vui lòng thử lại.';
    }
    if (normalized.contains('expired')) {
      return 'Liên kết chia sẻ đã hết hạn.';
    }
    if (normalized.contains('unsupported')) {
      return 'Tính năng này chưa được thiết bị hỗ trợ.';
    }
    if (normalized.contains('share') && normalized.contains('not found')) {
      return 'Không tìm thấy lịch chia sẻ.';
    }
    return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }
}
