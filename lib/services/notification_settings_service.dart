import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_settings_model.dart';
import 'firebase_service.dart';

class NotificationSettingsService {
  const NotificationSettingsService({required this.userId});

  final String userId;

  Stream<NotificationSettingsModel> watch() {
    if (!FirebaseService.isAvailable) {
      return Stream.fromFuture(loadCached());
    }
    return FirebaseService.notificationSettings(userId).snapshots().map((doc) {
      final settings = doc.exists
          ? NotificationSettingsModel.fromFirestore(doc)
          : const NotificationSettingsModel();
      _cache(settings);
      return settings;
    });
  }

  Future<NotificationSettingsModel> load() async {
    if (!FirebaseService.isAvailable) return loadCached();
    final doc = await FirebaseService.notificationSettings(userId).get();
    if (!doc.exists) return const NotificationSettingsModel();
    final settings = NotificationSettingsModel.fromFirestore(doc);
    await _cache(settings);
    return settings;
  }

  Future<void> save(NotificationSettingsModel settings) async {
    await _cache(settings);
    if (!FirebaseService.isAvailable) return;
    await FirebaseService.notificationSettings(
      userId,
    ).set(settings.toMap(), SetOptions(merge: true));
    await FirebaseService.userDoc(userId).set({
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSyncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<NotificationSettingsModel> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettingsModel(
      enabled: prefs.getBool(_key('enabled')) ?? true,
      nextClassReminderEnabled:
          prefs.getBool(_key('nextClassReminderEnabled')) ?? true,
      reminderMinutesBefore: prefs.getInt(_key('reminderMinutesBefore')) ?? 15,
      homeworkReminderEnabled:
          prefs.getBool(_key('homeworkReminderEnabled')) ?? true,
      examReminderEnabled: prefs.getBool(_key('examReminderEnabled')) ?? true,
      soundEnabled: prefs.getBool(_key('soundEnabled')) ?? true,
      defaultSound: prefs.getString(_key('defaultSound')) ?? 'default',
      permissionStatus: prefs.getString(_key('permissionStatus')) ?? 'unknown',
    );
  }

  Future<void> _cache(NotificationSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key('enabled'), settings.enabled);
    await prefs.setBool(
      _key('nextClassReminderEnabled'),
      settings.nextClassReminderEnabled,
    );
    await prefs.setInt(
      _key('reminderMinutesBefore'),
      settings.reminderMinutesBefore,
    );
    await prefs.setBool(
      _key('homeworkReminderEnabled'),
      settings.homeworkReminderEnabled,
    );
    await prefs.setBool(
      _key('examReminderEnabled'),
      settings.examReminderEnabled,
    );
    await prefs.setBool(_key('soundEnabled'), settings.soundEnabled);
    await prefs.setString(_key('defaultSound'), settings.defaultSound);
    await prefs.setString(_key('permissionStatus'), settings.permissionStatus);
  }

  String _key(String key) => 'notification.$userId.$key';
}
