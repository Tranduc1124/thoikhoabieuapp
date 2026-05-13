import 'dart:convert';

import 'schedule_model.dart';

class WidgetScheduleItem {
  const WidgetScheduleItem({
    required this.id,
    required this.subjectName,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.teacher,
    required this.color,
    required this.status,
  });

  final String id;
  final String subjectName;
  final int startTime;
  final int endTime;
  final String room;
  final String teacher;
  final int color;
  final String status;

  factory WidgetScheduleItem.fromSchedule(ScheduleModel schedule) {
    return WidgetScheduleItem(
      id: schedule.id,
      subjectName: schedule.subjectName,
      startTime: schedule.startTime,
      endTime: schedule.endTime,
      room: schedule.room,
      teacher: schedule.teacher,
      color: schedule.color,
      status: _statusFor(schedule),
    );
  }

  factory WidgetScheduleItem.fromMap(Map<String, dynamic> map) {
    return WidgetScheduleItem(
      id: map['id'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      startTime: (map['startTime'] as num?)?.toInt() ?? 0,
      endTime: (map['endTime'] as num?)?.toInt() ?? 0,
      room: map['room'] as String? ?? '',
      teacher: map['teacher'] as String? ?? '',
      color: (map['color'] as num?)?.toInt() ?? 0xFF6A8DFF,
      status: map['status'] as String? ?? 'upcoming',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectName': subjectName,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'teacher': teacher,
      'color': color,
      'status': status,
      'startTimeLabel': formatMinutes(startTime),
      'endTimeLabel': formatMinutes(endTime),
    };
  }

  static String encodeList(List<WidgetScheduleItem> items) {
    return jsonEncode(items.map((item) => item.toMap()).toList());
  }

  static List<WidgetScheduleItem> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map(
          (item) => WidgetScheduleItem.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static String _statusFor(ScheduleModel schedule) {
    final now = DateTime.now();
    if (now.weekday != schedule.dayOfWeek) return 'upcoming';
    final minutes = now.hour * 60 + now.minute;
    if (minutes >= schedule.endTime) return 'done';
    if (minutes >= schedule.startTime) return 'active';
    return 'upcoming';
  }
}
