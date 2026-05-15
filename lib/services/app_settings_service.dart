import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../models/app_settings_model.dart';
import '../utils/safe_json.dart';

class AppSettingsService {
  const AppSettingsService({required this.userId});

  final String userId;

  Future<AppSettingsModel> loadRemote() async {
    final data = await Api.call('settings.get');
    final settings = AppSettingsModel.fromMap(JsonSafe.map(data['settings']));
    await cache(settings);
    return settings;
  }

  Future<AppSettingsModel> load() async {
    try {
      return await loadRemote();
    } catch (_) {
      return loadCached();
    }
  }

  Future<void> save(AppSettingsModel settings) async {
    await cache(settings);
    await sync(settings);
  }

  Future<void> sync(AppSettingsModel settings) async {
    await Api.call('settings.update', data: settings.toMap());
  }

  Future<AppSettingsModel> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettingsModel(
      themeMode: prefs.getString(_key('themeMode')) ?? 'system',
      accentColor: prefs.getInt(_key('accentColor')) ?? 0xFF6A8DFF,
      liquidGlassEnabled: prefs.getBool(_key('liquidGlassEnabled')) ?? true,
      animationsEnabled: prefs.getBool(_key('animationsEnabled')) ?? true,
      dynamicIslandEnabled:
          prefs.getBool(_key('dynamicIslandEnabled')) ?? false,
      liveActivitiesEnabled:
          prefs.getBool(_key('liveActivitiesEnabled')) ?? false,
    );
  }

  Future<void> cache(AppSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key('themeMode'), settings.themeMode);
    await prefs.setInt(_key('accentColor'), settings.accentColor);
    await prefs.setBool(
      _key('liquidGlassEnabled'),
      settings.liquidGlassEnabled,
    );
    await prefs.setBool(_key('animationsEnabled'), settings.animationsEnabled);
    await prefs.setBool(
      _key('dynamicIslandEnabled'),
      settings.dynamicIslandEnabled,
    );
    await prefs.setBool(
      _key('liveActivitiesEnabled'),
      settings.liveActivitiesEnabled,
    );
  }

  String _key(String key) => 'appSettings.$userId.$key';
}
