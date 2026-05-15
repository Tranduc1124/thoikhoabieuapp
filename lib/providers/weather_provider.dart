import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weather_now_model.dart';
import '../services/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>(
  (ref) => const WeatherService(),
);

final homeWeatherProvider =
    AsyncNotifierProvider<HomeWeatherController, WeatherNowModel?>(
      HomeWeatherController.new,
    );

class HomeWeatherController extends AsyncNotifier<WeatherNowModel?> {
  @override
  Future<WeatherNowModel?> build() async {
    final service = ref.watch(weatherServiceProvider);
    final cached = await service.loadCached();
    unawaited(refreshWeather());
    return cached;
  }

  Future<WeatherNowModel?> refreshWeather() async {
    final service = ref.read(weatherServiceProvider);
    final next = await service.load();
    state = AsyncData(next);
    return next;
  }
}
