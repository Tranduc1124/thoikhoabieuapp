import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcQuickShareService {
  NfcQuickShareService._();

  static Future<bool> isSupported() async {
    if (kIsWeb) {
      return false;
    }
    try {
      final availability = await NfcManager.instance.checkAvailability();
      debugPrint('NFC availability=$availability');
      return false;
    } catch (error) {
      debugPrint('NFC support check failed: $error');
      return false;
    }
  }

  static Future<void> startQuickShare(String sharePayload) async {
    debugPrint('NFC quick share requested payload=$sharePayload');
    throw UnsupportedError(
      'NFC quick share chưa khả dụng trong bản build này.',
    );
  }
}
