import 'package:firebase_auth/firebase_auth.dart';

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
        'weak-password' => 'Mật khẩu quá yếu. Hãy dùng tối thiểu 6 ký tự.',
        'network-request-failed' =>
          'Không có mạng hoặc kết nối Firebase bị gián đoạn.',
        'operation-not-allowed' =>
          'Hãy bật Email/Password trong Firebase Authentication.',
        'account-exists-with-different-credential' =>
          'Email này đã đăng nhập bằng phương thức khác.',
        _ => error.message ?? 'Lỗi đăng nhập Firebase: ${error.code}.',
      };
    }
    return error.toString();
  }

  static String firestore(Object error) {
    if (error is FirebaseException) {
      return switch (error.code) {
        'failed-precondition' =>
          'Firestore đang thiếu composite index cho truy vấn này. Hãy deploy firestore.indexes.json bằng lệnh: firebase deploy --only firestore:indexes.',
        'permission-denied' =>
          'Firestore từ chối quyền truy cập. Kiểm tra rules: users/{userId} chỉ cho chính user đó đọc/ghi.',
        'unavailable' =>
          'Firestore đang không khả dụng hoặc mất mạng. Vui lòng thử lại.',
        'not-found' => 'Không tìm thấy dữ liệu Firestore cần đọc.',
        _ => error.message ?? 'Lỗi Firestore: ${error.code}.',
      };
    }
    return error.toString();
  }
}
