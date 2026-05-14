import 'package:cloud_firestore/cloud_firestore.dart';

import 'schedule_model.dart';

enum ShareScheduleType { today, week, subject, all }

class ShareScheduleModel {
  const ShareScheduleModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.shareType,
    required this.schedules,
    required this.subjects,
    required this.deepLink,
    required this.qrData,
    required this.isActive,
    required this.theme,
    required this.viewCount,
    this.profilePhoto,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final ShareScheduleType shareType;
  final List<ScheduleModel> schedules;
  final List<String> subjects;
  final String deepLink;
  final String qrData;
  final bool isActive;
  final String theme;
  final int viewCount;
  final String? profilePhoto;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  List<ScheduleModel> get schedulesSnapshot => schedules;
  String get link => deepLink;

  factory ShareScheduleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawSchedules =
        (data['schedules'] ?? data['schedulesSnapshot']) as List?;
    final rawSubjects = data['subjects'] as List?;
    final deepLink =
        data['deepLink'] as String? ?? 'thoikhoabieu://share/${doc.id}';
    return ShareScheduleModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? 'Sinh viên',
      title: data['title'] as String? ?? 'Thời khóa biểu',
      shareType: ShareScheduleType.values.firstWhere(
        (value) => value.name == (data['shareType'] ?? data['type']),
        orElse: () => ShareScheduleType.week,
      ),
      schedules: rawSchedules == null
          ? const []
          : rawSchedules
                .whereType<Map>()
                .map(
                  (item) => _scheduleFromMap(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false),
      subjects: rawSubjects == null
          ? const []
          : rawSubjects.map((item) => item.toString()).toList(growable: false),
      deepLink: deepLink,
      qrData: data['qrData'] as String? ?? deepLink,
      isActive: data['isActive'] as bool? ?? true,
      theme: data['theme'] as String? ?? 'liquidGlass',
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
      profilePhoto: data['profilePhoto'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': title,
      'shareType': shareType.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
      'theme': theme,
      'subjects': subjects,
      'schedules': schedules.map(_scheduleToMap).toList(growable: false),
      'timetableData': {
        'subjects': subjects,
        'scheduleCount': schedules.length,
      },
      'qrData': qrData,
      'deepLink': deepLink,
      'profilePhoto': profilePhoto,
      'viewCount': viewCount,
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
    };
  }

  ShareScheduleModel copyWith({
    String? title,
    ShareScheduleType? shareType,
    List<ScheduleModel>? schedules,
    List<String>? subjects,
    String? deepLink,
    String? qrData,
    bool? isActive,
    String? theme,
    int? viewCount,
    String? profilePhoto,
    DateTime? expiresAt,
  }) {
    return ShareScheduleModel(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      title: title ?? this.title,
      shareType: shareType ?? this.shareType,
      schedules: schedules ?? this.schedules,
      subjects: subjects ?? this.subjects,
      deepLink: deepLink ?? this.deepLink,
      qrData: qrData ?? this.qrData,
      isActive: isActive ?? this.isActive,
      theme: theme ?? this.theme,
      viewCount: viewCount ?? this.viewCount,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      createdAt: createdAt,
      updatedAt: updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
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
      'locationAddress': schedule.locationAddress,
      'latitude': schedule.latitude,
      'longitude': schedule.longitude,
      'appleMapsUrl': schedule.appleMapsUrl,
      'googleMapsUrl': schedule.googleMapsUrl,
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
      locationAddress: map['locationAddress'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      appleMapsUrl: map['appleMapsUrl'] as String?,
      googleMapsUrl: map['googleMapsUrl'] as String?,
      hasCustomColor: map.containsKey('color'),
      repeatWeekly: map['repeatWeekly'] as bool? ?? true,
      reminderEnabled: map['reminderEnabled'] as bool? ?? true,
      reminderMinutesBefore:
          (map['reminderMinutesBefore'] as num?)?.toInt() ?? 15,
    );
  }
}
