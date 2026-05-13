import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/schedule_model.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);
  }

  static Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> scheduleClassReminder(ScheduleModel schedule) async {
    if (!schedule.reminderEnabled) {
      await cancelSchedule(schedule.id);
      return;
    }

    final notificationTime = _nextClassDate(
      schedule,
    ).subtract(Duration(minutes: schedule.reminderMinutesBefore));
    final details = NotificationDetails(
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      android: AndroidNotificationDetails(
        'class_reminders',
        'Nhac lich hoc',
        channelDescription: 'Thong bao truoc gio hoc',
        importance: Importance.high,
        priority: Priority.high,
        color: schedule.displayColor,
      ),
    );

    await _plugin.zonedSchedule(
      _notificationId(schedule.id),
      'Sap den gio hoc ${schedule.subjectName}',
      '${formatMinutes(schedule.startTime)} - ${schedule.room.isEmpty ? 'Chua co phong' : schedule.room}',
      notificationTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: schedule.repeatWeekly
          ? DateTimeComponents.dayOfWeekAndTime
          : null,
    );
  }

  static Future<void> cancelSchedule(String scheduleId) {
    return _plugin.cancel(_notificationId(scheduleId));
  }

  static tz.TZDateTime _nextClassDate(ScheduleModel schedule) {
    final now = tz.TZDateTime.now(tz.local);
    var daysUntil = schedule.dayOfWeek - now.weekday;
    if (daysUntil < 0) daysUntil += 7;

    final candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntil,
      schedule.startTime ~/ 60,
      schedule.startTime % 60,
    );
    if (candidate.isBefore(now)) {
      return candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  static int _notificationId(String id) => id.hashCode & 0x7fffffff;
}
