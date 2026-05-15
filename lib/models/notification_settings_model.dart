import '../utils/safe_json.dart';

class NotificationSettingsModel {
  const NotificationSettingsModel({
    this.enabled = true,
    this.nextClassReminderEnabled = true,
    this.reminderMinutesBefore = 15,
    this.homeworkReminderEnabled = true,
    this.examReminderEnabled = true,
    this.soundEnabled = true,
    this.defaultSound = 'default',
    this.permissionStatus = 'unknown',
    this.updatedAt,
  });

  final bool enabled;
  final bool nextClassReminderEnabled;
  final int reminderMinutesBefore;
  final bool homeworkReminderEnabled;
  final bool examReminderEnabled;
  final bool soundEnabled;
  final String defaultSound;
  final String permissionStatus;
  final DateTime? updatedAt;

  factory NotificationSettingsModel.fromMap(dynamic data) {
    final safeData = JsonSafe.map(data);
    return NotificationSettingsModel(
      enabled: JsonSafe.boolean(safeData['enabled'], fallback: true),
      nextClassReminderEnabled: JsonSafe.boolean(
        safeData['nextClassReminderEnabled'],
        fallback: true,
      ),
      reminderMinutesBefore: JsonSafe.integer(
        safeData['reminderMinutesBefore'],
        fallback: 15,
      ),
      homeworkReminderEnabled: JsonSafe.boolean(
        safeData['homeworkReminderEnabled'],
        fallback: true,
      ),
      examReminderEnabled: JsonSafe.boolean(
        safeData['examReminderEnabled'],
        fallback: true,
      ),
      soundEnabled: JsonSafe.boolean(safeData['soundEnabled'], fallback: true),
      defaultSound: JsonSafe.string(
        safeData['defaultSound'],
        fallback: 'default',
      ),
      permissionStatus: JsonSafe.string(
        safeData['permissionStatus'],
        fallback: 'unknown',
      ),
      updatedAt: _readDate(safeData['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'nextClassReminderEnabled': nextClassReminderEnabled,
      'reminderMinutesBefore': reminderMinutesBefore,
      'homeworkReminderEnabled': homeworkReminderEnabled,
      'examReminderEnabled': examReminderEnabled,
      'soundEnabled': soundEnabled,
      'defaultSound': defaultSound,
      'permissionStatus': permissionStatus,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  NotificationSettingsModel copyWith({
    bool? enabled,
    bool? nextClassReminderEnabled,
    int? reminderMinutesBefore,
    bool? homeworkReminderEnabled,
    bool? examReminderEnabled,
    bool? soundEnabled,
    String? defaultSound,
    String? permissionStatus,
  }) {
    return NotificationSettingsModel(
      enabled: enabled ?? this.enabled,
      nextClassReminderEnabled:
          nextClassReminderEnabled ?? this.nextClassReminderEnabled,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      homeworkReminderEnabled:
          homeworkReminderEnabled ?? this.homeworkReminderEnabled,
      examReminderEnabled: examReminderEnabled ?? this.examReminderEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      defaultSound: defaultSound ?? this.defaultSound,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
