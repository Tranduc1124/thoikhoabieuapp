import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_settings_model.dart';
import '../models/schedule_model.dart';

enum AppNotificationPermissionStatus { granted, denied, unknown }

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

  static Future<bool> requestPermissions() async {
    final iosResult = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final androidResult = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    return iosResult ?? androidResult ?? true;
  }

  static Future<AppNotificationPermissionStatus> permissionStatus() async {
    final enabled = await requestPermissions();
    return enabled
        ? AppNotificationPermissionStatus.granted
        : AppNotificationPermissionStatus.denied;
  }

  static Future<void> scheduleClassReminder(
    ScheduleModel schedule, {
    NotificationSettingsModel settings = const NotificationSettingsModel(),
  }) async {
    await cancelSchedule(schedule.id);
    if (!settings.enabled ||
        !settings.nextClassReminderEnabled ||
        !schedule.reminderEnabled) {
      return;
    }

    final minutesBefore = schedule.reminderMinutesBefore > 0
        ? schedule.reminderMinutesBefore
        : settings.reminderMinutesBefore;
    final notificationTime = _nextClassDate(
      schedule,
    ).subtract(Duration(minutes: minutesBefore));
    final details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: settings.defaultSound == 'default'
            ? null
            : settings.defaultSound,
      ),
      android: AndroidNotificationDetails(
        'class_reminders',
        'Nhắc lịch học',
        channelDescription: 'Thông báo trước giờ học',
        importance: Importance.high,
        priority: Priority.high,
        color: schedule.displayColor,
      ),
    );

    await _plugin.zonedSchedule(
      _notificationId(schedule.id),
      'Sắp đến giờ học ${schedule.subjectName}',
      _classBody(schedule),
      notificationTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: schedule.repeatWeekly
          ? DateTimeComponents.dayOfWeekAndTime
          : null,
    );
  }

  static Future<void> rescheduleAllClassNotifications(
    List<ScheduleModel> schedules, {
    NotificationSettingsModel settings = const NotificationSettingsModel(),
  }) async {
    for (final schedule in schedules) {
      await scheduleClassReminder(schedule, settings: settings);
    }
  }

  static Future<void> scheduleHomeworkReminder({
    required String id,
    required String title,
    required DateTime dueAt,
    NotificationSettingsModel settings = const NotificationSettingsModel(),
  }) async {
    if (!settings.enabled || !settings.homeworkReminderEnabled) return;
    await _plugin.zonedSchedule(
      _notificationId('homework_$id'),
      'Sắp đến hạn bài tập',
      title,
      tz.TZDateTime.from(dueAt, tz.local),
      _basicDetails(settings),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> scheduleExamReminder({
    required String id,
    required String subjectName,
    required DateTime examAt,
    NotificationSettingsModel settings = const NotificationSettingsModel(),
  }) async {
    if (!settings.enabled || !settings.examReminderEnabled) return;
    await _plugin.zonedSchedule(
      _notificationId('exam_$id'),
      'Nhắc ôn thi $subjectName',
      'Bạn có lịch thi lúc ${examAt.hour.toString().padLeft(2, '0')}:${examAt.minute.toString().padLeft(2, '0')}.',
      tz.TZDateTime.from(examAt, tz.local),
      _basicDetails(settings),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelSchedule(String scheduleId) {
    return _plugin.cancel(_notificationId(scheduleId));
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  static String _classBody(ScheduleModel schedule) {
    final room = schedule.room.isEmpty ? 'chưa có phòng' : schedule.room;
    final teacher = schedule.teacher.isEmpty
        ? ''
        : ' Giáo viên: ${schedule.teacher}.';
    final note = schedule.note.isEmpty ? '' : ' ${schedule.note}';
    return 'Bạn có tiết ${schedule.subjectName} lúc '
        '${formatMinutes(schedule.startTime)} tại $room. Chuẩn bị nhé!$teacher$note';
  }

  static NotificationDetails _basicDetails(NotificationSettingsModel settings) {
    return NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: settings.defaultSound == 'default'
            ? null
            : settings.defaultSound,
      ),
      android: const AndroidNotificationDetails(
        'study_reminders',
        'Nhắc học tập',
        channelDescription: 'Bài tập, deadline và lịch thi',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
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
