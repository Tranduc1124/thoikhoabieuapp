import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  DeepLinkService._();

  static final _appLinks = AppLinks();
  static StreamSubscription<Uri>? _subscription;
  static bool _attached = false;

  static Future<void> attach(GoRouter router) async {
    if (_attached) return;
    _attached = true;
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _openUri(router, initial, source: 'initial');
    } catch (error) {
      debugPrint('Deep link initial read failed: $error');
    }
    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => _openUri(router, uri, source: 'stream'),
      onError: (Object error) => debugPrint('Deep link stream failed: $error'),
    );
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _attached = false;
  }

  static String? extractShareId(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final segments = uri.pathSegments;
      final shareIndex = segments.indexWhere(
        (item) => item == 'share' || item == 'shared',
      );
      if (shareIndex >= 0 && shareIndex + 1 < segments.length) {
        return segments[shareIndex + 1];
      }
      return segments.last;
    }
    return value;
  }

  static void _openUri(GoRouter router, Uri uri, {required String source}) {
    final segments = uri.pathSegments;
    final raw = uri.toString();
    if ((uri.host == 'profile' || segments.contains('profile')) &&
        segments.isNotEmpty) {
      final id = segments.last;
      debugPrint('Deep link opened source=$source uri=$uri profileCard=$id');
      if (id.isNotEmpty) {
        router.go('/profile-card-public/$id');
      }
      return;
    }
    final shareId = extractShareId(raw);
    debugPrint('Deep link opened source=$source uri=$uri shareId=$shareId');
    if (shareId == null || shareId.isEmpty) return;
    router.go('/shared/$shareId');
  }
}
