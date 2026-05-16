import '../utils/safe_json.dart';

class AppSettingsModel {
  const AppSettingsModel({
    this.themeMode = 'auto',
    this.accentColor = 0xFF6A8DFF,
    this.liquidGlassEnabled = true,
    this.animationsEnabled = true,
    this.dynamicIslandEnabled = true,
    this.liveActivitiesEnabled = true,
    this.updatedAt,
  });

  final String themeMode;
  final int accentColor;
  final bool liquidGlassEnabled;
  final bool animationsEnabled;
  final bool dynamicIslandEnabled;
  final bool liveActivitiesEnabled;
  final DateTime? updatedAt;

  factory AppSettingsModel.fromMap(dynamic data) {
    final safeData = JsonSafe.map(data);
    return AppSettingsModel(
      themeMode: JsonSafe.string(safeData['themeMode'], fallback: 'auto'),
      accentColor: JsonSafe.integer(
        safeData['accentColor'],
        fallback: 0xFF6A8DFF,
      ),
      liquidGlassEnabled: JsonSafe.boolean(
        safeData['liquidGlassEnabled'],
        fallback: true,
      ),
      animationsEnabled: JsonSafe.boolean(
        safeData['animationsEnabled'],
        fallback: true,
      ),
      dynamicIslandEnabled: JsonSafe.boolean(safeData['dynamicIslandEnabled']),
      liveActivitiesEnabled: JsonSafe.boolean(
        safeData['liveActivitiesEnabled'],
      ),
      updatedAt: _readDate(safeData['updatedAt']),
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
