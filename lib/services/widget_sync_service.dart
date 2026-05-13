import 'package:home_widget/home_widget.dart';

import '../models/schedule_model.dart';
import '../models/widget_schedule_item.dart';

class WidgetSyncService {
  WidgetSyncService._();

  static const appGroupId = 'group.com.minhduc.thoikhoabieuapp.widget';
  static const iOSWidgetName = 'ThoiKhoaBieuWidget';

  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (_) {
      // Widget sync must never block app startup.
    }
  }

  static Future<void> syncSchedules({
    required List<ScheduleModel> schedules,
    String themeMode = 'system',
  }) async {
    final today = DateTime.now().weekday;
    final todaySchedules =
        schedules.where((schedule) => schedule.dayOfWeek == today).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final next = _nextSchedule(todaySchedules);
    final widgetItems = todaySchedules
        .map(WidgetScheduleItem.fromSchedule)
        .toList();

    await _save('nextSubjectName', next?.subjectName ?? '');
    await _save(
      'nextStartTime',
      next == null ? '' : formatMinutes(next.startTime),
    );
    await _save('nextEndTime', next == null ? '' : formatMinutes(next.endTime));
    await _save('nextRoom', next?.room ?? '');
    await _save('nextTeacher', next?.teacher ?? '');
    await _save('todayClassCount', todaySchedules.length);
    await _save('todayClasses', WidgetScheduleItem.encodeList(widgetItems));
    await _save('themeMode', themeMode);
    await _save('lastUpdated', DateTime.now().toIso8601String());
    await refresh();
  }

  static Future<void> refresh() async {
    try {
      await HomeWidget.updateWidget(iOSName: iOSWidgetName);
    } catch (_) {}
  }

  static ScheduleModel? _nextSchedule(List<ScheduleModel> schedules) {
    if (schedules.isEmpty) return null;
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final upcoming = schedules.where((item) => item.endTime >= minutes).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (upcoming.isNotEmpty) return upcoming.first;
    return schedules.first;
  }

  static Future<void> _save<T>(String key, T value) async {
    try {
      await HomeWidget.saveWidgetData<T>(key, value);
    } catch (_) {}
  }
}
