import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../api/api.dart';

class BackendDiagnosticsResult {
  const BackendDiagnosticsResult({
    required this.reachable,
    required this.endpoint,
    required this.platform,
    required this.runtimePackageName,
    this.currentUserId,
    this.serverTime,
    this.message,
    this.error,
  });

  final bool reachable;
  final String endpoint;
  final String platform;
  final String runtimePackageName;
  final String? currentUserId;
  final String? serverTime;
  final String? message;
  final Object? error;

  List<String> toLogLines() {
    return [
      'Backend reachable: $reachable',
      'Endpoint: $endpoint',
      'Platform: $platform',
      'Runtime package/bundle id: $runtimePackageName',
      'Current user: ${currentUserId ?? "none"}',
      if (serverTime != null) 'Server time: $serverTime',
      if (message != null) 'Message: $message',
      if (error != null) 'Error: $error',
    ];
  }
}

class BackendDiagnosticsService {
  const BackendDiagnosticsService._();

  static Future<BackendDiagnosticsResult> checkBackendStatus() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final data = await Api.call(
        'system.ping',
        authenticated: false,
        data: const {},
      );
      final result = BackendDiagnosticsResult(
        reachable: true,
        endpoint: Api.baseUrl,
        platform: _platformName(),
        runtimePackageName: packageInfo.packageName,
        currentUserId: Api.currentSession?.uid,
        serverTime: data['serverTime']?.toString(),
        message: data['message']?.toString(),
      );
      debugPrint(result.toLogLines().join('\n'));
      return result;
    } catch (error) {
      final packageInfo = await PackageInfo.fromPlatform();
      final result = BackendDiagnosticsResult(
        reachable: false,
        endpoint: Api.baseUrl,
        platform: _platformName(),
        runtimePackageName: packageInfo.packageName,
        currentUserId: Api.currentSession?.uid,
        error: error,
      );
      debugPrint(result.toLogLines().join('\n'));
      return result;
    }
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
