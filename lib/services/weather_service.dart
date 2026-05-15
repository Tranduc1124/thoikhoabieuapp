import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather_now_model.dart';

class WeatherService {
  const WeatherService();

  static const _cacheKey = 'weather.default.current';
  static const _cacheMinutes = 45;
  static const _defaultLocationLabel = 'TP. Hồ Chí Minh';
  static final Uri _weatherUri = Uri.parse(
    'https://api.open-meteo.com/v1/forecast'
    '?latitude=10.8231'
    '&longitude=106.6297'
    '&current=temperature_2m,weather_code'
    '&timezone=Asia%2FHo_Chi_Minh',
  );

  Future<WeatherNowModel?> load() async {
    final cached = await loadCached();
    if (cached != null && !_isExpired(cached.updatedAt)) {
      return cached;
    }

    try {
      final remote = await fetchRemote();
      await cache(remote);
      return remote;
    } catch (_) {
      return cached;
    }
  }

  Future<WeatherNowModel?> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return WeatherNowModel.fromMap({...data, 'isFromCache': true});
    } catch (_) {
      return null;
    }
  }

  Future<WeatherNowModel> fetchRemote() async {
    final response = await http
        .get(_weatherUri)
        .timeout(const Duration(seconds: 4));
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final current = Map<String, dynamic>.from(
      (payload['current'] as Map?) ?? const {},
    );
    return WeatherNowModel(
      temperatureC: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      locationLabel: _defaultLocationLabel,
      updatedAt:
          DateTime.tryParse((current['time'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Future<void> cache(WeatherNowModel weather) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(weather.toMap()));
  }

  bool _isExpired(DateTime updatedAt) {
    return DateTime.now().difference(updatedAt) >
        const Duration(minutes: _cacheMinutes);
  }
}
