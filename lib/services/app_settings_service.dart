import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings_model.dart';
import 'firebase_service.dart';

class AppSettingsService {
  const AppSettingsService({required this.userId});

  final String userId;

  Stream<AppSettingsModel> watch() {
    if (!FirebaseService.isAvailable) {
      return Stream.fromFuture(loadCached());
    }
    return FirebaseService.appSettings(userId).snapshots().map((doc) {
      final settings = doc.exists
          ? AppSettingsModel.fromFirestore(doc)
          : const AppSettingsModel();
      _cache(settings);
      return settings;
    });
  }

  Future<AppSettingsModel> load() async {
    if (!FirebaseService.isAvailable) return loadCached();
    final doc = await FirebaseService.appSettings(userId).get();
    if (!doc.exists) return const AppSettingsModel();
    final settings = AppSettingsModel.fromFirestore(doc);
    await _cache(settings);
    return settings;
  }

  Future<void> save(AppSettingsModel settings) async {
    await _cache(settings);
    if (!FirebaseService.isAvailable) return;
    await FirebaseService.appSettings(
      userId,
    ).set(settings.toMap(), SetOptions(merge: true));
    await FirebaseService.userDoc(userId).set({
      'themeMode': settings.themeMode,
      'accentColor': settings.accentColor,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSyncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

  Future<void> _cache(AppSettingsModel settings) async {
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
