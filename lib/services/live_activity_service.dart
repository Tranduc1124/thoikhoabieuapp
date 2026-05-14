import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/schedule_model.dart';

class LiveActivityService {
  LiveActivityService._();

  static const _channel = MethodChannel('thoikhoabieu/live_activity');

  static Future<bool> isLiveActivitySupported() async {
    if (!_isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (error) {
      debugPrint('Live Activity support check failed: $error');
      return false;
    }
  }

  static Future<bool> isSupported() => isLiveActivitySupported();

  static Future<bool> areLiveActivitiesEnabled() async {
    if (!_isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('areEnabled') ?? false;
    } catch (error) {
      debugPrint('Live Activity enabled check failed: $error');
      return false;
    }
  }

  static Future<bool> isEnabled() => areLiveActivitiesEnabled();

  static Future<void> startClassActivity(ScheduleModel schedule) async {
    if (!await isLiveActivitySupported()) return;
    try {
      await _channel.invokeMethod<void>('start', {
        'current': _scheduleMap(schedule),
      });
    } catch (error) {
      debugPrint('Live Activity start failed: $error');
    }
  }

  static Future<void> startOrUpdateForSchedule(
    ScheduleModel? currentSchedule,
    ScheduleModel? nextSchedule,
  ) {
    return updateClassActivity(currentSchedule, nextSchedule);
  }

  static Future<void> updateClassActivity(
    ScheduleModel? currentSchedule,
    ScheduleModel? nextSchedule,
  ) async {
    if (!await isLiveActivitySupported()) return;
    try {
      await _channel.invokeMethod<void>('update', {
        'current': currentSchedule == null
            ? null
            : _scheduleMap(currentSchedule),
        'next': nextSchedule == null ? null : _scheduleMap(nextSchedule),
        'status': currentSchedule == null ? 'upcoming' : 'active',
        'remainingMinutes': currentSchedule == null
            ? 0
            : _remainingMinutes(currentSchedule),
      });
    } catch (error) {
      debugPrint('Live Activity update failed: $error');
    }
  }

  static Future<void> endClassActivity() async {
    if (!_isIOS) return;
    try {
      await _channel.invokeMethod<void>('end');
    } catch (error) {
      debugPrint('Live Activity end failed: $error');
    }
  }

  static Future<void> endActivity() => endClassActivity();
  static Future<void> stopAll() => endClassActivity();
  static Future<void> updateRemainingTime() async {
    if (!_isIOS) return;
    try {
      await _channel.invokeMethod<void>('updateRemainingTime');
    } catch (error) {
      debugPrint('Live Activity remaining time update failed: $error');
    }
  }

  static Future<void> showCompletedTodayActivity() async {
    if (!await isLiveActivitySupported()) return;
    try {
      await _channel.invokeMethod<void>('completedToday');
    } catch (error) {
      debugPrint('Live Activity completedToday failed: $error');
    }
  }

  static Future<void> refreshLiveActivityForToday({
    required List<ScheduleModel> schedules,
    required bool enabled,
  }) async {
    if (!enabled || !await isLiveActivitySupported()) {
      await endClassActivity();
      return;
    }
    final today = DateTime.now().weekday;
    final todaySchedules =
        schedules.where((schedule) => schedule.dayOfWeek == today).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (todaySchedules.isEmpty) {
      await endClassActivity();
      return;
    }

    final minutes = DateTime.now().hour * 60 + DateTime.now().minute;
    final current = todaySchedules
        .where(
          (schedule) =>
              minutes >= schedule.startTime && minutes < schedule.endTime,
        )
        .firstOrNull;
    final next = todaySchedules
        .where((schedule) => schedule.startTime > minutes)
        .firstOrNull;

    if (current != null) {
      await updateClassActivity(current, next);
      return;
    }
    if (next != null) {
      await updateClassActivity(null, next);
      return;
    }
    await showCompletedTodayActivity();
  }

  static Future<void> refreshForToday({
    required List<ScheduleModel> schedules,
    required bool enabled,
  }) {
    return refreshLiveActivityForToday(schedules: schedules, enabled: enabled);
  }

  static Map<String, Object?> _scheduleMap(ScheduleModel schedule) {
    return {
      'id': schedule.id,
      'subjectName': schedule.subjectName,
      'startTime': formatMinutes(schedule.startTime),
      'endTime': formatMinutes(schedule.endTime),
      'room': schedule.room,
      'teacher': schedule.teacher,
      'note': schedule.note,
      'color': schedule.color,
      'remainingMinutes': _remainingMinutes(schedule),
    };
  }

  static int _remainingMinutes(ScheduleModel schedule) {
    final minutes = DateTime.now().hour * 60 + DateTime.now().minute;
    return (schedule.endTime - minutes).clamp(0, 24 * 60);
  }

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
