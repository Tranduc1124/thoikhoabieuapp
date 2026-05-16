import '../models/schedule_model.dart';
import '../models/share_schedule_model.dart';
import 'deep_link_service.dart';
import 'nfc_quick_share_service.dart';

class ShareDebugService {
  const ShareDebugService._();

  static String? validateShareInput(String raw) {
    return DeepLinkService.extractShareId(raw);
  }

  static bool validateQrPayload(String payload) {
    final uri = Uri.tryParse(payload.trim());
    if (uri == null) return false;
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;
    return uri.pathSegments.contains('share') ||
        uri.pathSegments.contains('shared');
  }

  static Future<bool> isNfcQuickShareSupported() {
    return NfcQuickShareService.isSupported();
  }

  static ShareScheduleModel buildFakePreview(List<ScheduleModel> schedules) {
    return ShareScheduleModel(
      id: 'debug-preview',
      ownerId: 'debug',
      ownerName: 'Minh Đức',
      title: 'Bản xem thử chia sẻ',
      shareType: ShareScheduleType.week,
      schedules: schedules,
      subjects: schedules.map((item) => item.subjectName).toSet().toList(),
      deepLink: 'thoikhoabieu://share/debug-preview',
      qrData: 'https://minhduc.huutien.store/share/?id=debug-preview',
      isActive: true,
      theme: 'liquidGlass',
      viewCount: 0,
    );
  }
}
