import 'schedule_model.dart';
import '../utils/safe_json.dart';

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
    final safeData = JsonSafe.map(data);
    final rawSchedules = JsonSafe.list(
      safeData['schedules'] ?? safeData['schedulesSnapshot'],
    );
    final rawSubjects = JsonSafe.list(safeData['subjects']);
    final id = JsonSafe.string(safeData['id'] ?? safeData['share_id']);
    final publicUrl =
        (safeData['publicUrl'] ??
                safeData['public_url'] ??
                safeData['qrData'] ??
                safeData['qr_data'])
            ?.toString() ??
        'https://minhduc.huutien.store/share/$id';
    final deepLink =
        (safeData['deepLink'] ?? safeData['deep_link'])?.toString() ??
        'thoikhoabieu://share/$id';
    return ShareScheduleModel(
      id: id,
      ownerId: JsonSafe.string(safeData['ownerId'] ?? safeData['owner_id']),
      ownerName:
          (safeData['ownerName'] ?? safeData['owner_name'] ?? 'Sinh viên')
              .toString(),
      title: JsonSafe.string(safeData['title'], fallback: 'Thời khóa biểu'),
      shareType: ShareScheduleType.values.firstWhere(
        (value) => value.name == (safeData['shareType'] ?? safeData['type']),
        orElse: () => ShareScheduleType.week,
      ),
      schedules: rawSchedules
          .whereType<Map>()
          .map((item) => ScheduleModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      subjects: rawSubjects
          .map((item) => item.toString())
          .toList(growable: false),
      deepLink: deepLink,
      qrData: publicUrl,
      isActive: JsonSafe.boolean(
        safeData['isActive'] ?? safeData['is_active'],
        fallback: true,
      ),
      theme: JsonSafe.string(safeData['theme'], fallback: 'liquidGlass'),
      viewCount: JsonSafe.integer(
        safeData['viewCount'] ?? safeData['view_count'],
      ),
      profilePhoto:
          JsonSafe.string(
            safeData['profilePhoto'] ?? safeData['profile_photo'],
          ).trim().isEmpty
          ? null
          : JsonSafe.string(
              safeData['profilePhoto'] ?? safeData['profile_photo'],
            ),
      createdAt: _readDate(safeData['createdAt'] ?? safeData['created_at']),
      updatedAt: _readDate(safeData['updatedAt'] ?? safeData['updated_at']),
      expiresAt: _readDate(safeData['expiresAt'] ?? safeData['expires_at']),
      deletedAt: _readDate(safeData['deletedAt'] ?? safeData['deleted_at']),
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
