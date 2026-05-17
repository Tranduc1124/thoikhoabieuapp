import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../models/classroom_location_model.dart';
import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import '../services/app_feedback_service.dart';
import '../services/app_settings_service.dart';
import '../services/classroom_location_service.dart';
import '../services/live_activity_service.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';
import '../services/widget_sync_service.dart';

class ScheduleRepository {
  ScheduleRepository({required this.userId});

  final String userId;

  Future<List<ScheduleModel>> loadSchedules() async {
    final cached = await _loadCachedSchedules();
    if (cached != null) {
      unawaited(_refreshSchedulesCache());
      return cached;
    }
    return _fetchRemoteSchedules();
  }

  Future<List<ScheduleModel>> _fetchRemoteSchedules() async {
    try {
      final data = await Api.call('schedule.list');
      final items = (data['schedules'] as List? ?? const []);
      final schedules = items
          .whereType<Map>()
          .map((item) => ScheduleModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      await _cacheSchedules(schedules);
      return schedules;
    } catch (error) {
      throw AppUserMessageException(
        AppFeedbackService.messageFor(error),
        debugMessage: 'loadSchedules failed: $error',
      );
    }
  }

  Future<void> _refreshSchedulesCache() async {
    try {
      await _fetchRemoteSchedules();
    } catch (error) {
      debugPrint('Schedule background refresh failed for $userId: $error');
    }
  }

  Future<List<StudyLogModel>> loadStudyLogsForDate(DateTime date) async {
    try {
      final data = await Api.call(
        'studyLog.list',
        data: {'date': date.toIso8601String()},
      );
      final items = (data['studyLogs'] as List? ?? const []);
      return items
          .whereType<Map>()
          .map((item) => StudyLogModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (error) {
      throw AppUserMessageException(
        AppFeedbackService.messageFor(error),
        debugMessage: 'loadStudyLogsForDate failed: $error',
      );
    }
  }

  Future<List<StudyLogModel>> loadStudyLogsForWeek(DateTime date) async {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
    try {
      final data = await Api.call(
        'studyLog.list',
        data: {'weekStart': start.toIso8601String()},
      );
      final items = (data['studyLogs'] as List? ?? const []);
      return items
          .whereType<Map>()
          .map((item) => StudyLogModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (error) {
      throw AppUserMessageException(
        AppFeedbackService.messageFor(error),
        debugMessage: 'loadStudyLogsForWeek failed: $error',
      );
    }
  }

  Future<String> addSchedule(ScheduleModel schedule) async {
    _validate(schedule);
    try {
      final data = await Api.call(
        'schedule.create',
        data: schedule.toCreateMap(),
      );
      final id = (data['id'] ?? data['scheduleId'] ?? '').toString();
      final saved = schedule.copyWith(id: id);
      await _runBestEffort(
        () => _syncLocation(saved),
        label: 'sync location after add',
      );
      await _afterScheduleChanged();
      return id;
    } catch (error) {
      throw AppUserMessageException(
        AppFeedbackService.messageFor(error),
        debugMessage: 'addSchedule failed: $error',
      );
    }
  }

  Future<int> addSchedules(List<ScheduleModel> schedules) async {
    if (schedules.isEmpty) return 0;
    for (final schedule in schedules) {
      _validate(schedule);
    }
    try {
      final data = await Api.scheduleBulkCreate({
        'schedules': schedules.map((item) => item.toCreateMap()).toList(),
      });
      final items = (data['schedules'] as List? ?? const []);
      await _afterScheduleChanged();
      return items.length;
    } catch (error) {
      throw AppUserMessageException(
        AppFeedbackService.messageFor(error),
        debugMessage: 'addSchedules failed: $error',
      );
    }
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    _validate(schedule);
    try {
      await Api.call('schedule.update', data: schedule.toUpdateMap());
      await _runBestEffort(
        () => _syncLocation(schedule),
        label: 'sync location after update',
      );
      await _afterScheduleChanged();
    } catch (error) {
      throw AppUserMessageException(
        AppFeedbackService.messageFor(error),
        debugMessage: 'updateSchedule failed: $error',
      );
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await Api.call('schedule.delete', data: {'id': id});
    } catch (error) {
      throw AppUserMessageException(
        AppFeedbackService.messageFor(error),
        debugMessage: 'deleteSchedule failed: $error',
      );
    }

    await _runBestEffort(
      () => ClassroomLocationService(userId: userId).delete(_locationDocId(id)),
      label: 'delete classroom location',
    );
    await _runBestEffort(
      () => NotificationService.cancelSchedule(id),
      label: 'cancel schedule notification',
    );
    await _afterScheduleChanged();
  }

  Future<int> deleteSchedulesByDay(int dayOfWeek) async {
    try {
      final data = await Api.scheduleDeleteByDay(dayOfWeek);
      await _afterScheduleChanged();
      return (data['deletedCount'] as num?)?.toInt() ?? 0;
    } catch (error) {
      throw AppUserMessageException(
        AppFeedbackService.messageFor(error),
        debugMessage: 'deleteSchedulesByDay failed: $error',
      );
    }
  }

  Future<void> markStarted(ScheduleModel schedule, DateTime date) {
    return _upsertLog(
      schedule: schedule,
      date: date,
      status: StudyStatus.started,
    );
  }

  Future<void> markCompleted(
    ScheduleModel schedule,
    DateTime date, {
    String noteAfterClass = '',
  }) {
    return _upsertLog(
      schedule: schedule,
      date: date,
      status: StudyStatus.completed,
      noteAfterClass: noteAfterClass,
    );
  }

  Future<void> _upsertLog({
    required ScheduleModel schedule,
    required DateTime date,
    required StudyStatus status,
    String noteAfterClass = '',
  }) async {
    final id = '${schedule.id}_${date.year}_${date.month}_${date.day}';
    final normalized = DateTime(date.year, date.month, date.day);
    final log = StudyLogModel(
      id: id,
      scheduleId: schedule.id,
      subjectName: schedule.subjectName,
      date: normalized,
      status: status,
      noteAfterClass: noteAfterClass,
      completedAt: status == StudyStatus.completed ? DateTime.now() : null,
    );
    try {
      await Api.call('studyLog.update', data: log.toMap());
      await _afterScheduleChanged();
    } catch (error) {
      throw AppUserMessageException(
        AppFeedbackService.messageFor(error),
        debugMessage: 'upsertLog failed: $error',
      );
    }
  }

  Future<void> _afterScheduleChanged() async {
    try {
      final schedules = await _fetchRemoteSchedules();
      final settings = await NotificationSettingsService(userId: userId).load();
      await _runBestEffort(
        () => NotificationService.rescheduleAllClassNotifications(
          schedules,
          settings: settings,
        ),
        label: 'reschedule notifications',
      );
      final appSettings = await AppSettingsService(userId: userId).load();
      await _runBestEffort(
        () => WidgetSyncService.syncSchedules(
          schedules: schedules,
          themeMode: appSettings.themeMode,
        ),
        label: 'sync widget data',
      );
      await _runBestEffort(
        () => LiveActivityService.refreshLiveActivityForToday(
          schedules: schedules,
          enabled:
              appSettings.dynamicIslandEnabled &&
              appSettings.liveActivitiesEnabled,
        ),
        label: 'refresh live activity',
      );
      await _runBestEffort(
        () => Api.call('widget.sync'),
        label: 'sync widget backend state',
      );
      await _runBestEffort(
        () => Api.call('dynamicIsland.sync'),
        label: 'sync dynamic island backend state',
      );
      await _runBestEffort(
        () => Api.call('notification.sync'),
        label: 'sync notification backend state',
      );
    } catch (error) {
      debugPrint('Schedule refresh failed for $userId: $error');
    }
  }

  Future<List<ScheduleModel>?> _loadCachedSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((item) => ScheduleModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (error) {
      debugPrint('Schedule cache read failed for $userId: $error');
      return null;
    }
  }

  Future<void> _cacheSchedules(List<ScheduleModel> schedules) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        schedules.map((item) => item.toCreateMap()).toList(growable: false),
      );
      await prefs.setString(_cacheKey, encoded);
    } catch (error) {
      debugPrint('Schedule cache write failed for $userId: $error');
    }
  }

  String get _cacheKey => 'schedule.cache.$userId';

  Future<void> _syncLocation(ScheduleModel schedule) async {
    final locationId = _locationDocId(schedule.id);
    if (!schedule.hasMapLocation) {
      await ClassroomLocationService(userId: userId).delete(locationId);
      return;
    }
    final service = ClassroomLocationService(userId: userId);
    final location = ClassroomLocationModel(
      id: locationId,
      userId: userId,
      scheduleId: schedule.id,
      roomName: schedule.room,
      address: schedule.locationAddress,
      latitude: schedule.latitude,
      longitude: schedule.longitude,
      appleMapsUrl:
          schedule.appleMapsUrl ??
          service.buildAppleMapsUrl(
            address: schedule.locationAddress,
            latitude: schedule.latitude,
            longitude: schedule.longitude,
          ),
      googleMapsUrl:
          schedule.googleMapsUrl ??
          service.buildGoogleMapsUrl(
            address: schedule.locationAddress,
            latitude: schedule.latitude,
            longitude: schedule.longitude,
          ),
    );
    await service.save(location);
  }

  Future<void> _runBestEffort(
    Future<void> Function() action, {
    required String label,
  }) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Best effort failure [$label] userId=$userId error=$error');
    }
  }

  String _locationDocId(String scheduleId) => '${userId}_$scheduleId';

  void _validate(ScheduleModel schedule) {
    if (schedule.subjectName.trim().isEmpty) {
      throw const AppUserMessageException('Tên môn học không được để trống.');
    }
    if (schedule.endTime <= schedule.startTime) {
      throw const AppUserMessageException('Giờ kết thúc phải sau giờ bắt đầu.');
    }
  }
}
