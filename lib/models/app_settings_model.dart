class AppSettingsModel {
  const AppSettingsModel({
    this.themeMode = 'system',
    this.accentColor = 0xFF6A8DFF,
    this.liquidGlassEnabled = true,
    this.animationsEnabled = true,
    this.dynamicIslandEnabled = false,
    this.liveActivitiesEnabled = false,
    this.updatedAt,
  });

  final String themeMode;
  final int accentColor;
  final bool liquidGlassEnabled;
  final bool animationsEnabled;
  final bool dynamicIslandEnabled;
  final bool liveActivitiesEnabled;
  final DateTime? updatedAt;

  factory AppSettingsModel.fromMap(Map<String, dynamic>? data) {
    data ??= const {};
    return AppSettingsModel(
      themeMode: (data['themeMode'] ?? 'system').toString(),
      accentColor: (data['accentColor'] as num?)?.toInt() ?? 0xFF6A8DFF,
      liquidGlassEnabled: data['liquidGlassEnabled'] as bool? ?? true,
      animationsEnabled: data['animationsEnabled'] as bool? ?? true,
      dynamicIslandEnabled: data['dynamicIslandEnabled'] as bool? ?? false,
      liveActivitiesEnabled: data['liveActivitiesEnabled'] as bool? ?? false,
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'accentColor': accentColor,
      'liquidGlassEnabled': liquidGlassEnabled,
      'animationsEnabled': animationsEnabled,
      'dynamicIslandEnabled': dynamicIslandEnabled,
      'liveActivitiesEnabled': liveActivitiesEnabled,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  AppSettingsModel copyWith({
    String? themeMode,
    int? accentColor,
    bool? liquidGlassEnabled,
    bool? animationsEnabled,
    bool? dynamicIslandEnabled,
    bool? liveActivitiesEnabled,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      liquidGlassEnabled: liquidGlassEnabled ?? this.liquidGlassEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      dynamicIslandEnabled: dynamicIslandEnabled ?? this.dynamicIslandEnabled,
      liveActivitiesEnabled:
          liveActivitiesEnabled ?? this.liveActivitiesEnabled,
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
