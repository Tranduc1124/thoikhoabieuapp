import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/schedule_model.dart';

class ScheduleExportService {
  const ScheduleExportService();

  Future<File> exportCsv(List<ScheduleModel> schedules) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/thoikhoabieu_schedule.csv');
    final rows = <List<String>>[
      ['Day', 'Start', 'End', 'Subject', 'Room', 'Teacher', 'Location', 'Note'],
      for (final item in _sorted(schedules))
        [
          dayName(item.dayOfWeek),
          formatMinutes(item.startTime),
          formatMinutes(item.endTime),
          item.subjectName,
          item.room,
          item.teacher,
          item.locationAddress,
          item.note,
        ],
    ];
    await file.writeAsString(_csv(rows), flush: true);
    return file;
  }

  Future<File> exportICal(List<ScheduleModel> schedules) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/thoikhoabieu_schedule.ics');
    final now = DateTime.now().toUtc();
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//ThoiKhoaBieu//Schedule Export//VI',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      for (final item in _sorted(schedules)) ..._eventLines(item, now),
      'END:VCALENDAR',
    ];
    await file.writeAsString(lines.join('\r\n'), flush: true);
    return file;
  }

  List<ScheduleModel> _sorted(List<ScheduleModel> schedules) {
    return [...schedules]..sort((a, b) {
      final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
      return dayCompare == 0 ? a.startTime.compareTo(b.startTime) : dayCompare;
    });
  }

  List<String> _eventLines(ScheduleModel item, DateTime stamp) {
    final start = _nextDateForWeekday(
      item.dayOfWeek,
    ).add(Duration(minutes: item.startTime));
    final end = _nextDateForWeekday(
      item.dayOfWeek,
    ).add(Duration(minutes: item.endTime));
    final location = item.locationAddress.trim().isNotEmpty
        ? item.locationAddress
        : item.room;
    return [
      'BEGIN:VEVENT',
      'UID:${_escape(item.id)}@thoikhoabieu',
      'DTSTAMP:${_icalDateTime(stamp)}',
      'DTSTART:${_icalDateTime(start)}',
      'DTEND:${_icalDateTime(end)}',
      'RRULE:FREQ=WEEKLY',
      'SUMMARY:${_escape(item.subjectName)}',
      if (location.trim().isNotEmpty) 'LOCATION:${_escape(location)}',
      if (item.note.trim().isNotEmpty) 'DESCRIPTION:${_escape(item.note)}',
      'END:VEVENT',
    ];
  }

  DateTime _nextDateForWeekday(int weekday) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    final normalized = weekday.clamp(DateTime.monday, DateTime.sunday).toInt();
    final delta = (normalized - base.weekday + 7) % 7;
    return base.add(Duration(days: delta));
  }

  String _csv(List<List<String>> rows) {
    return rows
        .map((row) => row.map(_csvCell).join(','))
        .join(Platform.lineTerminator);
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _icalDateTime(DateTime value) {
    final utc = value.toUtc();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}T'
        '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  String _escape(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\n', r'\n');
  }
}
