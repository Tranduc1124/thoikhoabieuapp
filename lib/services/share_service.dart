import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/schedule_model.dart';
import '../models/share_schedule_model.dart';
import 'deep_link_service.dart';
import 'firebase_error_translator.dart';
import 'firebase_service.dart';

class ShareService {
  const ShareService({
    required this.userId,
    required this.ownerName,
    this.profilePhoto,
  });

  final String userId;
  final String ownerName;
  final String? profilePhoto;

  static const _shareHost = 'thoikhoabieuapp.page.link';
  static const _shareScheme = 'thoikhoabieu';

  Stream<List<ShareScheduleModel>> watchMyShares() async* {
    try {
      yield* FirebaseService.publicShares()
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(ShareScheduleModel.fromFirestore)
                .toList(growable: false),
          );
    } catch (error) {
      debugPrint('watchMyShares failed: $error');
      throw Exception(FirebaseErrorTranslator.firestore(error));
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
      throw Exception('Chưa có lịch học để chia sẻ.');
    }

    final shareId = existingShareId ?? const Uuid().v4();
    final deepLink = buildDeepLink(shareId);
    final webLink = buildWebLink(shareId);
    final subjects = schedules
        .map((item) => item.subjectName.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final share = ShareScheduleModel(
      id: shareId,
      ownerId: userId,
      ownerName: ownerName,
      title: title,
      shareType: type,
      schedules: schedules,
      subjects: subjects,
      deepLink: deepLink,
      qrData: webLink,
      isActive: true,
      theme: theme,
      viewCount: 0,
      profilePhoto: profilePhoto,
    );

    debugPrint(
      'share started shareId=$shareId type=${type.name} schedules=${schedules.length}',
    );
    try {
      await FirebaseService.publicShares()
          .doc(shareId)
          .set(share.toCreateMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 12));
      debugPrint('firestore upload success shareId=$shareId');
      debugPrint('link generated deep=$deepLink web=$webLink');
      return share;
    } catch (error) {
      debugPrint('share upload failed shareId=$shareId error=$error');
      throw Exception(FirebaseErrorTranslator.firestore(error));
    }
  }

  Future<ShareScheduleModel?> getPublicShare(String shareIdOrLink) async {
    final normalized = normalizeShareId(shareIdOrLink);
    if (normalized == null) {
      throw Exception('Liên kết chia sẻ không hợp lệ.');
    }

    try {
      final doc = await FirebaseService.publicShares()
          .doc(normalized)
          .get()
          .timeout(const Duration(seconds: 12));
      if (!doc.exists) return null;

      final share = ShareScheduleModel.fromFirestore(doc);
      if (share.expiresAt != null &&
          share.expiresAt!.isBefore(DateTime.now())) {
        debugPrint('share expired shareId=$normalized');
        return share.copyWith(isActive: false);
      }
      if (!share.isActive) {
        debugPrint('share inactive shareId=$normalized');
        return share;
      }

      await doc.reference.update({
        'viewCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('public share loaded shareId=$normalized');
      return share.copyWith(viewCount: share.viewCount + 1);
    } catch (error) {
      debugPrint('public share load failed shareId=$normalized error=$error');
      throw Exception(FirebaseErrorTranslator.firestore(error));
    }
  }

  Future<int> importSchedules(
    ShareScheduleModel share, {
    required List<ScheduleModel> schedules,
  }) async {
    if (schedules.isEmpty) return 0;
    try {
      final existing = await FirebaseService.schedules(userId).get();
      final keys = existing.docs.map((doc) {
        final data = doc.data();
        return _scheduleKey(
          subjectName: data['subjectName'] as String? ?? '',
          dayOfWeek: (data['dayOfWeek'] as num?)?.toInt() ?? 0,
          startTime: (data['startTime'] as num?)?.toInt() ?? 0,
          endTime: (data['endTime'] as num?)?.toInt() ?? 0,
        );
      }).toSet();

      final batch = FirebaseService.firestore.batch();
      var imported = 0;
      for (final schedule in schedules) {
        final key = _scheduleKey(
          subjectName: schedule.subjectName,
          dayOfWeek: schedule.dayOfWeek,
          startTime: schedule.startTime,
          endTime: schedule.endTime,
        );
        if (keys.contains(key)) {
          continue;
        }
        final doc = FirebaseService.schedules(userId).doc();
        batch.set(doc, {
          ...schedule.toCreateMap(),
          'importedFromShareId': share.id,
          'importedAt': FieldValue.serverTimestamp(),
        });
        keys.add(key);
        imported++;
      }

      if (imported > 0) {
        await batch.commit().timeout(const Duration(seconds: 12));
      }
      debugPrint('import success shareId=${share.id} imported=$imported');
      return imported;
    } catch (error) {
      debugPrint('import failed shareId=${share.id} error=$error');
      throw Exception(FirebaseErrorTranslator.firestore(error));
    }
  }

  Future<void> setActive(String shareId, bool active) async {
    try {
      await FirebaseService.publicShares().doc(shareId).update({
        'isActive': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('share active updated shareId=$shareId active=$active');
    } catch (error) {
      debugPrint('setActive failed shareId=$shareId error=$error');
      throw Exception(FirebaseErrorTranslator.firestore(error));
    }
  }

  Future<void> deleteShare(String shareId) async {
    try {
      await FirebaseService.publicShares().doc(shareId).delete();
      debugPrint('share deleted shareId=$shareId');
    } catch (error) {
      debugPrint('deleteShare failed shareId=$shareId error=$error');
      throw Exception(FirebaseErrorTranslator.firestore(error));
    }
  }

  Future<XFile> captureShareImage({
    required ScreenshotController controller,
    required String filename,
  }) async {
    try {
      final bytes = await controller.capture(pixelRatio: 3);
      if (bytes == null) {
        throw StateError('Không thể tạo ảnh chia sẻ.');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename.png');
      await file.writeAsBytes(bytes);
      debugPrint('qr generated image=${file.path}');
      return XFile(file.path, mimeType: 'image/png');
    } catch (error) {
      debugPrint('captureShareImage failed error=$error');
      throw Exception(FirebaseErrorTranslator.readable(error));
    }
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
    debugPrint('share image saved path=${file.path}');
    return file;
  }

  Future<void> copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    debugPrint('share link copied');
  }

  Future<void> shareLink(ShareScheduleModel share) async {
    debugPrint('share sheet opening type=link shareId=${share.id}');
    await SharePlus.instance.share(
      ShareParams(
        text:
            '${share.title}\n${buildWebLink(share.id)}\nMở trực tiếp trong app: ${share.deepLink}\nShare ID: ${share.id}',
      ),
    );
    debugPrint('share sheet opened type=link shareId=${share.id}');
  }

  Future<void> shareImage(XFile file, {String? text}) async {
    debugPrint('share sheet opening type=image path=${file.path}');
    await SharePlus.instance.share(ShareParams(files: [file], text: text));
    debugPrint('share sheet opened type=image');
  }

  String buildDeepLink(String shareId) => '$_shareScheme://share/$shareId';

  String buildWebLink(String shareId) => 'https://$_shareHost/share/$shareId';

  static String? normalizeShareId(String input) {
    return DeepLinkService.extractShareId(input);
  }

  static String _scheduleKey({
    required String subjectName,
    required int dayOfWeek,
    required int startTime,
    required int endTime,
  }) {
    return '${subjectName.trim().toLowerCase()}|$dayOfWeek|$startTime|$endTime';
  }
}
