import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ScheduleModel {
  const ScheduleModel({
    required this.id,
    required this.subjectName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.teacher,
    required this.note,
    required this.color,
    required this.repeatWeekly,
    required this.reminderEnabled,
    required this.reminderMinutesBefore,
    this.hasCustomColor = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String subjectName;
  final int dayOfWeek;
  final int startTime;
  final int endTime;
  final String room;
  final String teacher;
  final String note;
  final int color;
  final bool hasCustomColor;
  final bool repeatWeekly;
  final bool reminderEnabled;
  final int reminderMinutesBefore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Color get displayColor => Color(color);
  Duration get duration => Duration(minutes: endTime - startTime);

  factory ScheduleModel.empty() {
    return const ScheduleModel(
      id: '',
      subjectName: '',
      dayOfWeek: 1,
      startTime: 7 * 60,
      endTime: 8 * 60 + 30,
      room: '',
      teacher: '',
      note: '',
      color: 0xFF6A8DFF,
      repeatWeekly: true,
      reminderEnabled: true,
      reminderMinutesBefore: 10,
    );
  }

  factory ScheduleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final hasColor = data.containsKey('color');
    return ScheduleModel(
      id: doc.id,
      subjectName: data['subjectName'] as String? ?? '',
      dayOfWeek: (data['dayOfWeek'] as num?)?.toInt() ?? 1,
      startTime: _readMinutes(data['startTime']),
      endTime: _readMinutes(data['endTime']),
      room: data['room'] as String? ?? '',
      teacher: data['teacher'] as String? ?? '',
      note: data['note'] as String? ?? '',
      color: _readColor(data['color']),
      hasCustomColor: hasColor,
      repeatWeekly: data['repeatWeekly'] as bool? ?? true,
      reminderEnabled: data['reminderEnabled'] as bool? ?? false,
      reminderMinutesBefore:
          (data['reminderMinutesBefore'] as num?)?.toInt() ?? 10,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'subjectName': subjectName,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'teacher': teacher,
      'note': note,
      'color': color,
      'repeatWeekly': repeatWeekly,
      'reminderEnabled': reminderEnabled,
      'reminderMinutesBefore': reminderMinutesBefore,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    final map = toCreateMap()..remove('createdAt');
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  ScheduleModel copyWith({
    String? id,
    String? subjectName,
    int? dayOfWeek,
    int? startTime,
    int? endTime,
    String? room,
    String? teacher,
    String? note,
    int? color,
    bool? repeatWeekly,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      teacher: teacher ?? this.teacher,
      note: note ?? this.note,
      color: color ?? this.color,
      hasCustomColor: color != null ? true : hasCustomColor,
      repeatWeekly: repeatWeekly ?? this.repeatWeekly,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static int _readMinutes(Object? value) {
    if (value is num) return value.toInt();
    if (value is String && value.contains(':')) {
      final parts = value.split(':').map(int.tryParse).toList();
      if (parts.length >= 2 && parts[0] != null && parts[1] != null) {
        return parts[0]! * 60 + parts[1]!;
      }
    }
    return 0;
  }

  static int _readColor(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      final normalized = trimmed.startsWith('#')
          ? '0xFF${trimmed.substring(1)}'
          : trimmed.startsWith('0x')
          ? trimmed
          : trimmed.length == 6
          ? '0xFF$trimmed'
          : trimmed;
      return int.tryParse(normalized) ?? 0xFF2F80ED;
    }
    return 0xFF6A8DFF;
  }
}

String formatMinutes(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

String dayName(int dayOfWeek) {
  const names = {
    1: 'Thứ 2',
    2: 'Thứ 3',
    3: 'Thứ 4',
    4: 'Thứ 5',
    5: 'Thứ 6',
    6: 'Thứ 7',
    7: 'CN',
  };
  return names[dayOfWeek] ?? 'Thứ 2';
}
