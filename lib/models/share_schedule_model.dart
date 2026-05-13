import 'package:cloud_firestore/cloud_firestore.dart';

import 'schedule_model.dart';

enum ShareScheduleType { today, week, subject, all }

class ShareScheduleModel {
  const ShareScheduleModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.type,
    required this.title,
    required this.schedulesSnapshot,
    required this.isActive,
    required this.viewCount,
    this.createdAt,
    this.expiresAt,
    this.theme = 'liquidGlass',
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final ShareScheduleType type;
  final String title;
  final List<ScheduleModel> schedulesSnapshot;
  final bool isActive;
  final int viewCount;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final String theme;

  String get link => 'https://your-domain.com/share/$id';

  factory ShareScheduleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawSchedules = data['schedulesSnapshot'];
    return ShareScheduleModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? 'Sinh viên',
      type: ShareScheduleType.values.firstWhere(
        (value) => value.name == data['type'],
        orElse: () => ShareScheduleType.week,
      ),
      title: data['title'] as String? ?? 'Thời khoá biểu',
      schedulesSnapshot: rawSchedules is List
          ? rawSchedules
                .whereType<Map>()
                .map(
                  (item) => _scheduleFromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      isActive: data['isActive'] as bool? ?? true,
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      theme: data['theme'] as String? ?? 'liquidGlass',
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'type': type.name,
      'title': title,
      'schedulesSnapshot': schedulesSnapshot
          .map((schedule) => _scheduleToMap(schedule))
          .toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
      'isActive': isActive,
      'viewCount': viewCount,
      'theme': theme,
    };
  }

  static Map<String, dynamic> _scheduleToMap(ScheduleModel schedule) {
    return {
      'id': schedule.id,
      'subjectName': schedule.subjectName,
      'dayOfWeek': schedule.dayOfWeek,
      'startTime': schedule.startTime,
      'endTime': schedule.endTime,
      'room': schedule.room,
      'teacher': schedule.teacher,
      'note': schedule.note,
      'color': schedule.color,
      'repeatWeekly': schedule.repeatWeekly,
      'reminderEnabled': schedule.reminderEnabled,
      'reminderMinutesBefore': schedule.reminderMinutesBefore,
    };
  }

  static ScheduleModel _scheduleFromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      dayOfWeek: (map['dayOfWeek'] as num?)?.toInt() ?? 1,
      startTime: (map['startTime'] as num?)?.toInt() ?? 0,
      endTime: (map['endTime'] as num?)?.toInt() ?? 0,
      room: map['room'] as String? ?? '',
      teacher: map['teacher'] as String? ?? '',
      note: map['note'] as String? ?? '',
      color: (map['color'] as num?)?.toInt() ?? 0xFF6A8DFF,
      repeatWeekly: map['repeatWeekly'] as bool? ?? true,
      reminderEnabled: map['reminderEnabled'] as bool? ?? true,
      reminderMinutesBefore:
          (map['reminderMinutesBefore'] as num?)?.toInt() ?? 15,
    );
  }
}
