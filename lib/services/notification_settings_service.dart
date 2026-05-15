import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../models/notification_settings_model.dart';

class NotificationSettingsService {
  const NotificationSettingsService({required this.userId});

  final String userId;

  Future<NotificationSettingsModel> load() async {
    try {
      final data = await Api.call('notification.settings');
      final settings = NotificationSettingsModel.fromMap(
        Map<String, dynamic>.from(data['settings'] as Map),
      );
      await _cache(settings);
      return settings;
    } catch (_) {
      return loadCached();
    }
  }

  Future<void> save(NotificationSettingsModel settings) async {
    await _cache(settings);
    await Api.call('notification.settings', data: settings.toMap());
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
