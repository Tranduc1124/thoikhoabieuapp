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

  factory NotificationSettingsModel.fromMap(Map<String, dynamic>? data) {
    data ??= const {};
    return NotificationSettingsModel(
      enabled: data['enabled'] as bool? ?? true,
      nextClassReminderEnabled:
          data['nextClassReminderEnabled'] as bool? ?? true,
      reminderMinutesBefore:
          (data['reminderMinutesBefore'] as num?)?.toInt() ?? 15,
      homeworkReminderEnabled: data['homeworkReminderEnabled'] as bool? ?? true,
      examReminderEnabled: data['examReminderEnabled'] as bool? ?? true,
      soundEnabled: data['soundEnabled'] as bool? ?? true,
      defaultSound: (data['defaultSound'] ?? 'default').toString(),
      permissionStatus: (data['permissionStatus'] ?? 'unknown').toString(),
      updatedAt: _readDate(data['updatedAt']),
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
