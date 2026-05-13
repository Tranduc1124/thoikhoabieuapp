import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/schedule_model.dart';
import '../models/share_schedule_model.dart';
import 'firebase_service.dart';

class ShareService {
  const ShareService({required this.userId, required this.ownerName});

  final String userId;
  final String ownerName;

  Stream<List<ShareScheduleModel>> watchMyShares() {
    return FirebaseService.publicShares()
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ShareScheduleModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<ShareScheduleModel> createShare({
    required ShareScheduleType type,
    required String title,
    required List<ScheduleModel> schedules,
  }) async {
    final id = const Uuid().v4();
    final share = ShareScheduleModel(
      id: id,
      ownerId: userId,
      ownerName: ownerName,
      type: type,
      title: title,
      schedulesSnapshot: schedules,
      isActive: true,
      viewCount: 0,
    );
    await FirebaseService.publicShares().doc(id).set(share.toCreateMap());
    return share;
  }

  Future<ShareScheduleModel?> getPublicShare(String shareId) async {
    final doc = await FirebaseService.publicShares().doc(shareId.trim()).get();
    if (!doc.exists) return null;
    final share = ShareScheduleModel.fromFirestore(doc);
    if (!share.isActive) return share;
    await doc.reference.update({'viewCount': FieldValue.increment(1)});
    return share;
  }

  Future<void> setActive(String shareId, bool active) {
    return FirebaseService.publicShares().doc(shareId).update({
      'isActive': active,
    });
  }

  Future<void> deleteShare(String shareId) {
    return FirebaseService.publicShares().doc(shareId).delete();
  }

  Future<XFile> captureShareImage({
    required ScreenshotController controller,
    required String filename,
  }) async {
    final bytes = await controller.capture(pixelRatio: 3);
    if (bytes == null) throw StateError('Không tạo được ảnh chia sẻ.');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.png');
    await file.writeAsBytes(bytes);
    return XFile(file.path, mimeType: 'image/png');
  }

  Future<void> shareLink(ShareScheduleModel share) {
    return SharePlus.instance.share(
      ShareParams(
        text: '${share.title}\n${share.link}\nMã chia sẻ: ${share.id}',
      ),
    );
  }

  Future<void> shareImage(XFile file, {String? text}) {
    return SharePlus.instance.share(ShareParams(files: [file], text: text));
  }
}
