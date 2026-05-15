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
    this.deletedAt,
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
  final DateTime? deletedAt;

  List<ScheduleModel> get schedulesSnapshot => schedules;
  String get publicUrl => qrData;
  String get link => qrData;
  bool get isDeleted => deletedAt != null;

  factory ShareScheduleModel.fromMap(Map<String, dynamic> data) {
    final rawSchedules =
        (data['schedules'] ?? data['schedulesSnapshot']) as List?;
    final rawSubjects = data['subjects'] as List?;
    final id = (data['id'] ?? data['share_id'] ?? '').toString();
    final publicUrl =
        (data['publicUrl'] ??
                data['public_url'] ??
                data['qrData'] ??
                data['qr_data'])
            ?.toString() ??
        'https://minhduc.huutien.store/share/$id';
    final deepLink =
        (data['deepLink'] ?? data['deep_link'])?.toString() ??
        'thoikhoabieu://share/$id';
    return ShareScheduleModel(
      id: id,
      ownerId: (data['ownerId'] ?? data['owner_id'] ?? '').toString(),
      ownerName: (data['ownerName'] ?? data['owner_name'] ?? 'Sinh viên')
          .toString(),
      title: (data['title'] ?? 'Thời khóa biểu').toString(),
      shareType: ShareScheduleType.values.firstWhere(
        (value) => value.name == (data['shareType'] ?? data['type']),
        orElse: () => ShareScheduleType.week,
      ),
      schedules: rawSchedules == null
          ? const []
          : rawSchedules
                .whereType<Map>()
                .map(
                  (item) =>
                      ScheduleModel.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false),
      subjects: rawSubjects == null
          ? const []
          : rawSubjects.map((item) => item.toString()).toList(growable: false),
      deepLink: deepLink,
      qrData: publicUrl,
      isActive: data['isActive'] as bool? ?? data['is_active'] as bool? ?? true,
      theme: (data['theme'] ?? 'liquidGlass').toString(),
      viewCount:
          (data['viewCount'] ?? data['view_count'] as num?)?.toInt() ?? 0,
      profilePhoto:
          data['profilePhoto']?.toString() ?? data['profile_photo']?.toString(),
      createdAt: _readDate(data['createdAt'] ?? data['created_at']),
      updatedAt: _readDate(data['updatedAt'] ?? data['updated_at']),
      expiresAt: _readDate(data['expiresAt'] ?? data['expires_at']),
      deletedAt: _readDate(data['deletedAt'] ?? data['deleted_at']),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': title,
      'shareType': shareType.name,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
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
      'publicUrl': qrData,
      'profilePhoto': profilePhoto,
      'viewCount': viewCount,
      'expiresAt': expiresAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
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
    DateTime? deletedAt,
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
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static Map<String, dynamic> _scheduleToMap(ScheduleModel schedule) {
    return schedule.toCreateMap();
  }

  static DateTime? _readDate(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
