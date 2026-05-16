import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../api/api.dart';
import '../models/schedule_model.dart';
import '../models/share_schedule_model.dart';
import '../utils/safe_json.dart';
import 'app_feedback_service.dart';
import 'deep_link_service.dart';

class ShareService {
  const ShareService({
    required this.userId,
    required this.ownerName,
    this.profilePhoto,
  });

  final String userId;
  final String ownerName;
  final String? profilePhoto;
  String get _mySharesCacheKey => 'shares.$userId.myLinks';

  static const _shareHost = 'minhduc.huutien.store';
  static const _shareScheme = 'thoikhoabieu';

  Future<List<ShareScheduleModel>> listMyShares() async {
    try {
      final data = await Api.call('share.myLinks');
      final items = (data['shares'] as List? ?? const []);
      await _cacheList(_mySharesCacheKey, items);
      return _parseShares(items);
    } catch (_) {
      return _parseShares(await _loadCachedList(_mySharesCacheKey));
    }
  }

  Future<ShareScheduleModel> createOrUpdateShare({
    String? existingShareId,
    required ShareScheduleType type,
    required String title,
    required List<ScheduleModel> schedules,
    String theme = 'liquidGlass',
  }) async {
    if (schedules.isEmpty) {
      throw const AppUserMessageException('Chưa có lịch học để chia sẻ.');
    }

    final shareId = existingShareId ?? const Uuid().v4();
    final share = ShareScheduleModel(
      id: shareId,
      ownerId: userId,
      ownerName: ownerName,
      title: title,
      shareType: type,
      schedules: schedules,
      subjects: schedules
          .map((item) => item.subjectName.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false),
      deepLink: buildDeepLink(shareId),
      qrData: buildWebLink(shareId),
      isActive: true,
      theme: theme,
      viewCount: 0,
      profilePhoto: profilePhoto,
    );
    final data = await Api.call('share.create', data: share.toCreateMap());
    final shareData = JsonSafe.map(data['share']);
    return ShareScheduleModel.fromMap(
      shareData.isEmpty ? share.toCreateMap() : shareData,
    );
  }

  Future<ShareScheduleModel?> getPublicShare(String shareIdOrLink) async {
    final normalized = normalizeShareId(shareIdOrLink);
    if (normalized == null) {
      throw const AppUserMessageException('Liên kết chia sẻ không hợp lệ.');
    }
    final data = await Api.call(
      'share.get',
      authenticated: false,
      data: {'shareId': normalized},
    );
    final shareMap = data['share'];
    if (shareMap is! Map) return null;
    return ShareScheduleModel.fromMap(Map<String, dynamic>.from(shareMap));
  }

  Future<int> importSchedules(
    ShareScheduleModel share, {
    required List<ScheduleModel> schedules,
  }) async {
    if (schedules.isEmpty) return 0;
    final data = await Api.call(
      'share.import',
      data: {
        'shareId': share.id,
        'schedules': schedules.map((item) => item.toCreateMap()).toList(),
      },
    );
    return (data['importedCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> setActive(String shareId, bool active) async {
    await Api.call(
      'share.update',
      data: {'shareId': shareId, 'isActive': active},
    );
  }

  Future<void> deleteShare(String shareId) async {
    await Api.call('share.delete', data: {'shareId': shareId});
  }

  Future<XFile> captureShareImage({
    required ScreenshotController controller,
    required String filename,
  }) async {
    final bytes = await controller.capture(pixelRatio: 3);
    if (bytes == null) {
      throw const AppUserMessageException('Không thể tạo ảnh chia sẻ.');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.png');
    await file.writeAsBytes(bytes);
    return XFile(file.path, mimeType: 'image/png');
  }

  Future<File> saveShareImage({
    required ScreenshotController controller,
    required String filename,
  }) async {
    final image = await captureShareImage(
      controller: controller,
      filename: filename,
    );
    final bytes = await image.readAsBytes();
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${dir.path}/shared_timetables');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
    final file = File('${outputDir.path}/$filename.png');
    await file.writeAsBytes(bytes, flush: true);
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }
      await Gal.putImage(file.path);
    } on GalException catch (error) {
      throw AppUserMessageException(
        _galleryErrorMessage(error),
        debugMessage: error.toString(),
      );
    }
    return file;
  }

  Future<void> copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
  }

  Future<void> shareLink(ShareScheduleModel share) async {
    await SharePlus.instance.share(
      ShareParams(text: '${share.title}\n${share.publicUrl}'),
    );
  }

  Future<void> shareImage(XFile file, {String? text}) async {
    await SharePlus.instance.share(ShareParams(files: [file], text: text));
  }

  Future<void> openPublicLink(String shareIdOrLink) async {
    final normalized = normalizeShareId(shareIdOrLink);
    if (normalized == null) {
      throw const AppUserMessageException('Liên kết chia sẻ không hợp lệ.');
    }
    final uri = Uri.parse(buildWebLink(normalized));
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw const AppUserMessageException('Không thể mở liên kết chia sẻ.');
    }
  }

  String buildDeepLink(String shareId) => '$_shareScheme://share/$shareId';

  String buildWebLink(String shareId) =>
      'https://$_shareHost/share/?id=${Uri.encodeComponent(shareId)}';

  String _galleryErrorMessage(GalException error) {
    return switch (error.type) {
      GalExceptionType.accessDenied =>
        'Bạn cần cấp quyền Photos/Gallery để lưu ảnh QR.',
      GalExceptionType.notEnoughSpace =>
        'Máy không còn đủ dung lượng để lưu ảnh QR.',
      GalExceptionType.notSupportedFormat =>
        'Định dạng ảnh QR chưa được thiết bị hỗ trợ.',
      GalExceptionType.unexpected =>
        'Không thể lưu ảnh vào Photos/Gallery lúc này.',
    };
  }

  static String? normalizeShareId(String input) {
    return DeepLinkService.extractShareId(input);
  }

  List<ShareScheduleModel> _parseShares(List<Object?> items) {
    return items
        .whereType<Map>()
        .map(
          (item) => ShareScheduleModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .where((share) => !share.isDeleted)
        .toList(growable: false);
  }

  Future<void> _cacheList(String key, List<Object?> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }

  Future<List<Object?>> _loadCachedList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded;
  }
}
