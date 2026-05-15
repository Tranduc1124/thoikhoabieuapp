import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../api/api.dart';
import 'app_feedback_service.dart';

class BackendDiagnosticsResult {
  const BackendDiagnosticsResult({
    required this.isConnected,
    required this.platform,
    required this.versionLabel,
    required this.isSignedIn,
    this.updatedAt,
    this.note,
    this.error,
  });

  final bool isConnected;
  final String platform;
  final String versionLabel;
  final bool isSignedIn;
  final String? updatedAt;
  final String? note;
  final Object? error;

  List<String> toDisplayLines() {
    return [
      isConnected ? 'Kết nối ổn định' : 'Chưa thể kết nối lúc này',
      'Thiết bị: $platform',
      'Phiên bản ứng dụng: $versionLabel',
      isSignedIn ? 'Bạn đang đăng nhập' : 'Bạn chưa đăng nhập',
      if (updatedAt != null) 'Cập nhật gần nhất: $updatedAt',
      if (note != null && note!.trim().isNotEmpty) note!,
      if (error != null) AppFeedbackService.messageFor(error!),
    ];
  }
}

class BackendDiagnosticsService {
  const BackendDiagnosticsService._();

  static Future<BackendDiagnosticsResult> checkBackendStatus() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final versionLabel = '${packageInfo.version} (${packageInfo.buildNumber})';

    try {
      final data = await Api.call(
        'system.ping',
        authenticated: false,
        data: const {},
      );
      final result = BackendDiagnosticsResult(
        isConnected: true,
        platform: _platformName(),
        versionLabel: versionLabel,
        isSignedIn: Api.currentSession?.uid.isNotEmpty == true,
        updatedAt: data['serverTime']?.toString(),
        note: 'Mọi thứ đang hoạt động bình thường.',
      );
      debugPrint(result.toDisplayLines().join('\n'));
      return result;
    } catch (error) {
      final result = BackendDiagnosticsResult(
        isConnected: false,
        platform: _platformName(),
        versionLabel: versionLabel,
        isSignedIn: Api.currentSession?.uid.isNotEmpty == true,
        error: error,
      );
      debugPrint(result.toDisplayLines().join('\n'));
      return result;
    }
  }

  static String _platformName() {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'iPhone',
      TargetPlatform.android => 'Android',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      _ => 'Thiết bị của bạn',
    };
  }
}
