import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import 'firebase_service.dart';

class BackupService {
  const BackupService({required this.userId});

  final String userId;

  Future<File> exportUserDataToJson() async {
    final userDoc = await FirebaseService.userDoc(userId).get();
    final schedules = await FirebaseService.schedules(userId).get();
    final logs = await FirebaseService.studyLogs(userId).get();
    final notification = await FirebaseService.notificationSettings(
      userId,
    ).get();
    final appSettings = await FirebaseService.appSettings(userId).get();

    final payload = {
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'user': _sanitize(userDoc.data()),
      'settings': {
        'notification': _sanitize(notification.data()),
        'app': _sanitize(appSettings.data()),
      },
      'schedules': schedules.docs.map((doc) {
        final schedule = ScheduleModel.fromFirestore(doc);
        return schedule.toCreateMap()
          ..remove('createdAt')
          ..remove('updatedAt');
      }).toList(),
      'studyLogs': logs.docs.map((doc) {
        final log = StudyLogModel.fromFirestore(doc);
        return log.toMap();
      }).toList(),
    };

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/thoikhoabieu_backup_$userId.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(_sanitize(payload)),
    );
    await FirebaseService.userDoc(userId).set({
      'lastSyncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return file;
  }

  Future<void> importUserDataFromJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw ArgumentError('File backup không hợp lệ.');
    }
    final schedules = decoded['schedules'];
    if (schedules is List) {
      final batch = FirebaseService.firestore.batch();
      for (final item in schedules.whereType<Map>()) {
        final doc = FirebaseService.schedules(userId).doc();
        batch.set(doc, {
          ...Map<String, dynamic>.from(item),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Object? _sanitize(Object? value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is FieldValue) return null;
    if (value is Map) {
      return value.map(
        (key, child) => MapEntry(key.toString(), _sanitize(child)),
      );
    }
    if (value is List) return value.map(_sanitize).toList();
    return value;
  }
}
