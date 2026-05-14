import 'package:flutter/foundation.dart';
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
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      // The app is targeted at Vietnamese students. This keeps scheduled class
      // reminders aligned on iOS even when the build machine timezone is UTC.
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (error) {
      debugPrint('Notification timezone fallback failed: $error');
    }

    const settings = InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint(
          'Notification tapped: id=${response.id}, payload=${response.payload}',
        );
      },
    );
    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    await initialize();
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
    final granted = iosResult ?? androidResult ?? true;
    if (!granted) debugPrint('Notification permission denied by user/system.');
    return granted;
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
    await initialize();
    await cancelSchedule(schedule.id);
    if (!settings.enabled ||
        !settings.nextClassReminderEnabled ||
        !schedule.reminderEnabled) {
      debugPrint('Skip class notification for ${schedule.id}: disabled.');
      return;
    }

    final minutesBefore = schedule.reminderMinutesBefore > 0
        ? schedule.reminderMinutesBefore
        : settings.reminderMinutesBefore;
    final notificationTime = _nextReminderDate(schedule, minutesBefore);
    if (notificationTime == null) {
      debugPrint(
        'Skip class notification in the past: ${schedule.id} ${schedule.subjectName}',
      );
      return;
    }

    final details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: settings.soundEnabled,
        sound: !settings.soundEnabled || settings.defaultSound == 'default'
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

    final id = _notificationId(schedule.id);
    await _plugin.zonedSchedule(
      id,
      'Sắp đến giờ học ${schedule.subjectName}',
      _classBody(schedule),
      notificationTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: schedule.repeatWeekly
          ? DateTimeComponents.dayOfWeekAndTime
          : null,
      payload: schedule.id,
    );
    debugPrint(
      'Scheduled class notification id=$id subject=${schedule.subjectName} at=$notificationTime',
    );
  }

  static Future<void> rescheduleAllClassNotifications(
    List<ScheduleModel> schedules, {
    NotificationSettingsModel settings = const NotificationSettingsModel(),
  }) async {
    await initialize();
    if (!settings.enabled || !settings.nextClassReminderEnabled) {
      await cancelAllClassNotifications(schedules);
      return;
    }
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
    await initialize();
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
    await initialize();
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

  static Future<List<PendingNotificationRequest>>
  pendingNotificationRequests() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    debugPrint('Pending notifications: ${pending.length}');
    for (final item in pending) {
      debugPrint('Pending notification id=${item.id} title=${item.title}');
    }
    return pending;
  }

  static Future<void> scheduleTestNotification() async {
    await initialize();
    final granted = await requestPermissions();
    if (!granted) return;
    final scheduledAt = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 10));
    await _plugin.zonedSchedule(
      999001,
      'Test thông báo Thời Khoá Biểu',
      'Nếu bạn thấy thông báo này, local notification đang hoạt động.',
      scheduledAt,
      _basicDetails(const NotificationSettingsModel()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'debug_test',
    );
    debugPrint('Scheduled test notification at=$scheduledAt');
  }

  static Future<void> cancelSchedule(String scheduleId) async {
    await initialize();
    final id = _notificationId(scheduleId);
    await _plugin.cancel(id);
    await _plugin.cancel(scheduleId.hashCode & 0x7fffffff);
    debugPrint('Cancelled class notification id=$id scheduleId=$scheduleId');
  }

  static Future<void> cancelAllClassNotifications(
    List<ScheduleModel> schedules,
  ) async {
    for (final schedule in schedules) {
      await cancelSchedule(schedule.id);
    }
  }

  static Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

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
        presentSound: settings.soundEnabled,
        sound: !settings.soundEnabled || settings.defaultSound == 'default'
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

  static tz.TZDateTime? _nextReminderDate(
    ScheduleModel schedule,
    int minutesBefore,
  ) {
    final classStart = _nextClassDate(schedule);
    var reminder = classStart.subtract(Duration(minutes: minutesBefore));
    final now = tz.TZDateTime.now(tz.local);
    if (reminder.isBefore(now)) {
      if (schedule.repeatWeekly) {
        reminder = reminder.add(const Duration(days: 7));
      } else {
        return null;
      }
    }
    return reminder;
  }

  static int _notificationId(String id) {
    var hash = 2166136261;
    for (final codeUnit in id.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }
}
