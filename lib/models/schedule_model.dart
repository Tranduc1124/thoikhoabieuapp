import 'package:flutter/material.dart';

class ScheduleModel {
  static const _unset = Object();

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
    this.locationAddress = '',
    this.latitude,
    this.longitude,
    this.appleMapsUrl,
    this.googleMapsUrl,
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
  final String locationAddress;
  final double? latitude;
  final double? longitude;
  final String? appleMapsUrl;
  final String? googleMapsUrl;
  final bool hasCustomColor;
  final bool repeatWeekly;
  final bool reminderEnabled;
  final int reminderMinutesBefore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Color get displayColor => Color(color);
  Duration get duration => Duration(minutes: endTime - startTime);
  bool get hasMapLocation =>
      locationAddress.trim().isNotEmpty ||
      (latitude != null && longitude != null);

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

  factory ScheduleModel.fromMap(Map<String, dynamic> data) {
    final hasColor = data.containsKey('color');
    return ScheduleModel(
      id: (data['id'] ?? data['scheduleId'] ?? '').toString(),
      subjectName: (data['subjectName'] ?? data['subject_name'] ?? '')
          .toString(),
      dayOfWeek:
          (data['dayOfWeek'] ?? data['day_of_week'] as num?)?.toInt() ?? 1,
      startTime: _readMinutes(data['startTime'] ?? data['start_time']),
      endTime: _readMinutes(data['endTime'] ?? data['end_time']),
      room: (data['room'] ?? '').toString(),
      teacher: (data['teacher'] ?? '').toString(),
      note: (data['note'] ?? '').toString(),
      color: _readColor(data['color']),
      locationAddress:
          (data['locationAddress'] ?? data['location_address'] ?? '')
              .toString(),
      latitude: _readDouble(data['latitude']),
      longitude: _readDouble(data['longitude']),
      appleMapsUrl:
          data['appleMapsUrl']?.toString() ??
          data['apple_maps_url']?.toString(),
      googleMapsUrl:
          data['googleMapsUrl']?.toString() ??
          data['google_maps_url']?.toString(),
      hasCustomColor: hasColor,
      repeatWeekly:
          data['repeatWeekly'] as bool? ??
          data['repeat_weekly'] as bool? ??
          true,
      reminderEnabled:
          data['reminderEnabled'] as bool? ??
          data['reminder_enabled'] as bool? ??
          false,
      reminderMinutesBefore:
          (data['reminderMinutesBefore'] ??
                  data['reminder_minutes_before'] as num?)
              ?.toInt() ??
          10,
      createdAt: _readDate(data['createdAt'] ?? data['created_at']),
      updatedAt: _readDate(data['updatedAt'] ?? data['updated_at']),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'subjectName': subjectName,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'teacher': teacher,
      'note': note,
      'color': color,
      'locationAddress': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'appleMapsUrl': appleMapsUrl,
      'googleMapsUrl': googleMapsUrl,
      'repeatWeekly': repeatWeekly,
      'reminderEnabled': reminderEnabled,
      'reminderMinutesBefore': reminderMinutesBefore,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateMap() => toCreateMap();

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
    String? locationAddress,
    Object? latitude = _unset,
    Object? longitude = _unset,
    Object? appleMapsUrl = _unset,
    Object? googleMapsUrl = _unset,
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
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: identical(latitude, _unset)
          ? this.latitude
          : latitude as double?,
      longitude: identical(longitude, _unset)
          ? this.longitude
          : longitude as double?,
      appleMapsUrl: identical(appleMapsUrl, _unset)
          ? this.appleMapsUrl
          : appleMapsUrl as String?,
      googleMapsUrl: identical(googleMapsUrl, _unset)
          ? this.googleMapsUrl
          : googleMapsUrl as String?,
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
    if (value is String) return int.tryParse(value) ?? 0;
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

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String && value.trim().isNotEmpty) {
      return double.tryParse(value);
    }
    return null;
  }

  static DateTime? _readDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
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
